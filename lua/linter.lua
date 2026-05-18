local M = {}

---@alias ListOptions "quickfix"|"trouble"

---@class PluginOptions
---@field auto_open? boolean
---@field list? ListOptions
---@field debug? boolean

---@type PluginOptions
local default_options = {
	auto_open = true,
	list = "quickfix",
	debug = false,
}

---@param opts PluginOptions
M.setup = function(opts)
	local plugin_options = vim.tbl_deep_extend("force", default_options, opts or {})
	local original_attach = vim.lsp.config["ts_ls"].on_attach

	vim.lsp.config("ts_ls", {
		on_attach = function(client, bufnr)
			vim.api.nvim_buf_create_user_command(0, "Tsc", function()
				local workspace = ""
				local rootFiles = {
					"tsconfig.json",
				}

				for _, file in ipairs(rootFiles) do
					local res = vim.fn.findfile(file, ".;")
					if #res > 0 then
						if plugin_options.debug then
							print("Found tsconfig.json: " .. res)
						end
						workspace = vim.fn.getcwd() .. "/" .. res:gsub("/tsconfig.json", "")
						break
					end
				end

				if not workspace then
					print("No tsconfig.json found")
					return
				end

				-- since tsc gives relative paths from tsconfig.json we temporarily change the cwd to the workspace root
				-- this is to support monorepos where there might be more than one tsconfig.json
				-- and the tsconfig.json might be in a subdirectory (ie ./applications/app1/tsconfig.json)
				local oldCwd = vim.fn.getcwd()
				vim.fn.chdir(workspace)

				if plugin_options.debug then
					print("oldCwd: " .. oldCwd)
					print("workspaceRoot: " .. workspace)
					print("cwd after chdir: " .. vim.fn.getcwd())
				end

				-- using npx to use the project's typescript version and not depend on a global install
				vim.api.nvim_command(":compiler tsc | setlocal makeprg=npx\\ tsc")
				vim.api.nvim_command(":make")

				-- change back to original cwd
				vim.fn.chdir(oldCwd)
				if plugin_options.debug then
					print("oldCwd: " .. oldCwd)
					print("workspaceRoot: " .. workspace)
					print("cwd after changing back: " .. vim.fn.getcwd())
				end

				if not plugin_options.auto_open then
					return
				end

				local quckfixEntries = vim.fn.getqflist()
				if #quckfixEntries == 0 then
					print("No typescript errors found")
					return
				end

				for i = #quckfixEntries, 1, -1 do
					if not quckfixEntries[i].valid then
						table.remove(quckfixEntries, i)
					end
				end

				if plugin_options.list == "quickfix" then
					vim.api.nvim_command(":copen")
				end

				if plugin_options.list == "trouble" and require("trouble") then
					require("trouble").open({ mode = "quickfix" })
				end
			end, { nargs = 0 })

			if original_attach then
				original_attach(client, bufnr)
			end
		end,
	})
end

return M
