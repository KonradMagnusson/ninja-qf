local M = {}

local lazy = require("ninja-qf.lazy")


M.opts = {
	qf_format = "{file:>35}|L{line:>5}:C{col:3}|{type:=7}|  {text}",
}

local function populate_config( opts )
	M.opts = vim.tbl_extend( "force", M.opts, opts )
end

local notify_opts = {
	title = "ninja-qf"
}

local function registered_autocmds()
	vim.api.nvim_create_autocmd( "FileType", {
		pattern = "cpp",
		callback = function(ev)
			local addr = "127.0.0.1:48199" -- hardcoded for now.
			if pcall( vim.fn.serverstart, addr ) then
				vim.notify( "RPC server listening on " .. addr, vim.log.levels.INFO, notify_opts )
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
			fmt = string.gsub( fmt, "{col:([<%=>]?%d+)}",	  "{col;" ..item.col.. ";col:%1}" )
			fmt = ExpandPadding( fmt, "col" )
			fmt = string.gsub( fmt, "{file:([<%=>]?%d+)}",  "{file;"  ..file..   ";file:%1}" )
			fmt = ExpandPadding( fmt, "file" )
			fmt = string.gsub( fmt, "{line:([<%=>]?%d+)}",  "{line;"..item.lnum..";line:%1}" )
			fmt = ExpandPadding( fmt, "line" )
			fmt = string.gsub( fmt, "{type:([<%=>]?%d+)}",  "{type;"  ..type..   ";type:%1}" )
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
	registered_autocmds()
	set_options()
	set_quickfixtextfunc()
end

return M
