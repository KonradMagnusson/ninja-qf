local M = {}

local lazy = require("ninja-qf.lazy")


M.opts = {
	qf_format = "{type:=7}|{file:>35}|L{line:>5}|C{col:>3}|  {text}"
}

local function populate_config( opts )
	M.opts = vim.tbl_extend( "force", M.opts, opts )
end

local notify_opts = {
	title = "ninja-qf"
}

local function register_autocmds()
	vim.api.nvim_create_autocmd( "FileType", {
		pattern = "cpp",
		callback = function(ev)
			local addr = "127.0.0.1:48199" -- hardcoded for now.
			if pcall( vim.fn.serverstart, addr ) then
				vim.notify( "RPC server listening on " .. addr, vim.log.levels.INFO, notify_opts )
			end
		end
	})

	vim.api.nvim_create_autocmd( "FileType", {
		pattern = "qf",
		callback = function(ev)
			vim.api.nvim_buf_set_option( 0, "filetype", "ninja-qf" )
		end
	})

	vim.api.nvim_create_autocmd( "TextChanged", {
		callback = function(ev)
			if vim.api.nvim_buf_get_option( ev.buf, "filetype" ) ~= "ninja-qf" then
				return
			end

			-- these are tbqfh garbage. Their order is hardcoded, and it breaks other syntax groups.
			vim.cmd( "syn clear qfFileName" )
			vim.cmd( "syn clear qfSeparator" )
			vim.cmd( "syn clear qfLineNr" )
			vim.cmd( "syn clear qfError" )

			vim.cmd( "syn keyword ninjaQfError error" )
			vim.cmd( "syn keyword ninjaQfWarning warning" )
			vim.cmd( "syn keyword ninjaQfNote note" )
			vim.cmd( "syn match qfSeparator '|'" )
			vim.api.nvim_set_hl( 0, "ninjaQfSeparator",{ link = "qfSeparator" } )
			vim.api.nvim_set_hl( 0, "ninjaQfColNr",    { link = "qfLineNr" } )
			vim.api.nvim_set_hl( 0, "ninjaQfLineNr",   { link = "qfLineNr" } )
			vim.api.nvim_set_hl( 0, "ninjaQfFileName", { link = "qfFileName" } )
			vim.api.nvim_set_hl( 0, "ninjaQfError",    { link = "DiagnosticError" } )
			vim.api.nvim_set_hl( 0, "ninjaQfWarning",  { link = "DiagnosticWarning" } )
			vim.api.nvim_set_hl( 0, "ninjaQfNote",     { link = "DiagnosticNote" } )
			vim.api.nvim_set_hl( 0, "ninjaQfText",     { link = "Normal" } )

			for line = 0, vim.api.nvim_buf_line_count( ev.buf ) do
				local line_str = vim.api.nvim_buf_get_lines( ev.buf, line, line+1, false )[1] or ""

				local columns = {}
				for column in string.gmatch(M.opts.qf_format, "([^|]+)") do
					if string.find( column, "{col" )  then table.insert( columns, "ninjaQfColNr" ) end
					if string.find( column, "{file" ) then table.insert( columns, "ninjaQfFileName" ) end
					if string.find( column, "{line" ) then table.insert( columns, "ninjaQfLineNr" ) end
					if string.find( column, "{type" ) then table.insert( columns, "ninjaQfType" ) end
					if string.find( column, "{text" ) then table.insert( columns, "ninjaQfText" ) end
				end

				local total_width = 0
				local i = 1
				for col in string.gmatch(line_str, "[^|]+") do
					local width = i ~= #columns and #col or -1
					local start_col = total_width + i - 1
					local end_col = width ~= -1 and ( start_col + width ) or -1 -- -1 means "to EOL"

					vim.api.nvim_buf_add_highlight( ev.buf, -1, columns[i], line, start_col, end_col )

					if width then
						total_width = total_width + width
					end
					i = i + 1
				end

			end
		end
	})
end

local function set_options()
	-- configured to match clang's output.
	vim.opt.errorformat = [[%-GIn file%.%#:,%W%f:%l:%c: %tarning: %m,%E%f:%l:%c: %trror: %m,%C%s,%C%m,%Z%m,%E%>ld.%.%#: %trror: %m,%C%>>>> referenced by %s (%f:%l),%-C%>>>>%s,%C%s,%-Z,%-G%.%#]]

end

local function ExpandPadding( source, c )
	local re = "{"..c..";(.*);"..c..":([<%=>]?)(%d+)}"
	local captureless = "{"..c..";.*;"..c..":[<%=>]?%d+}"

	local _, _, txt, just, pad_width = string.find( source, re )
	pad_width = tonumber(pad_width) or 0
	pad_width = math.max(pad_width - #txt, 0)

	if just == ">" then
		return string.gsub( source, captureless, string.rep( " ", pad_width ) .. txt )
	end
	if just == "=" then
		local lpad = (pad_width / 2) - (pad_width / 2) % 1
		local rpad = (pad_width / 2) + (pad_width / 2) % 1
		return string.gsub( source, captureless, string.rep( " ", lpad ) .. txt .. string.rep( " ", rpad ) )
	end
		return string.gsub( source, captureless, txt .. string.rep( " ", pad_width ) )

end

M.NinjaQFTextFunc = function( info )
	if info.quickfix ~= 1 then
		return -- idc about loclist atm
	end

	local ret = {}

	local list = vim.fn.getqflist( { id = info.id, items = 0, qfbufnr = 0, context = 0 } )
	for i = info.start_idx, info.end_idx do
		local item = list.items[ i ]
		if item.valid then
			local full_path = vim.api.nvim_buf_get_name( item.bufnr )
			local file = string.match( full_path, "[^/]+%.%w+" )

			local type = "?"
			if item.type == "e" then type = "error" end
			if item.type == "w" then type = "warning" end
			if item.type == "n" then type = "note" end

			local fmt = M.opts.qf_format
			fmt = string.gsub( fmt, "{col:([<=>]?%d+)}",   "{col;" ..item.col.. ";col:%1}" )
			fmt = ExpandPadding( fmt, "col" )
			fmt = string.gsub( fmt, "{file:([<=>]?%d+)}",  "{file;"  ..file..   ";file:%1}" )
			fmt = ExpandPadding( fmt, "file" )
			fmt = string.gsub( fmt, "{line:([<=>]?%d+)}",  "{line;"..item.lnum..";line:%1}" )
			fmt = ExpandPadding( fmt, "line" )
			fmt = string.gsub( fmt, "{type:([<=>]?%d+)}",  "{type;"  ..type..   ";type:%1}" )
			fmt = ExpandPadding( fmt, "type" )

			fmt = string.gsub( fmt, "{text}", item.text )
			table.insert( ret, fmt)
		end
	end

	return ret
end

local function set_quickfixtextfunc()
	vim.cmd([[
		function! NinjaQFTextFunc(info)
			return v:lua.require('ninja-qf').NinjaQFTextFunc(a:info)
		endfunction
	]])
	vim.o.quickfixtextfunc = "NinjaQFTextFunc"
end


function M.setup( opts )
	populate_config( opts )
	register_autocmds()
	set_options()
	set_quickfixtextfunc()
end

return M
