local M = {}

local lazy = require("ninja-qf.lazy")


M.opts = {
	qf_format = "ignored for now",
	pad_target = "also ignored for now"
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

M.NinjaQFTextFunc = function( info )
	if info.quickfix ~= 1 then
		return -- idc about loclist atm
	end

	local ret = {}

	local qf_format = "{file}|L{line}:{col}{padding}{type}|{text}" -- hardcoded until I cbf with figuring out how to do syntax groups in a sane way
	local pad_target = 50 -- (temporary) target column to pad (the end of ) {padding} to

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

			-- (temporary) - hardcoded padding calculations to match the hardcoded format above
			local pad_width = pad_target - ( #file + 2 + #tostring(item.lnum) + 1 + #tostring(item.col) + #type + 1)
			local padding = string.rep(" ", pad_width)

			local fmt = qf_format
			fmt = string.gsub( fmt, "{col}", item.col )
			fmt = string.gsub( fmt, "{file}", file )
			fmt = string.gsub( fmt, "{line}", item.lnum )
			fmt = string.gsub( fmt, "{padding}", padding )
			fmt = string.gsub( fmt, "{text}", item.text )
			fmt = string.gsub( fmt, "{type}", type )
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
