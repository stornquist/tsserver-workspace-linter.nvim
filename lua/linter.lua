local M = {}

M.setup = function(opts)
    local status, lspconfig = pcall(require, "lspconfig")
    if not status then
        print("lspconfig not found")
    end

    if not lspconfig["tsserver"] then
        print("make sure tsserver is installed and setup before loading tsserver-workspace-lint")
    else
        lspconfig["tsserver"].setup({
            on_attach = function(client, bufnr)
                local original = lspconfig["tsserver"].manager.config.capabilities.on_attach
                vim.api.nvim_buf_create_user_command(0, "Tsc", function()
                    local workspace = vim.lsp.get_active_clients({ bufnr = 0, name = "tsserver" })[1].config.root_dir
                    vim.api.nvim_command(":compiler tsc | setlocal makeprg=tsc\\ -p\\ " .. workspace)
                    vim.api.nvim_command(":make")
                    local len = vim.api.nvim_exec2("echo len(getqflist())", { output = true }).output
                    if tonumber(len) > 0 then
                        vim.api.nvim_command(":copen")
                    else
                        print("No typescript errors found")
                    end
                end, { nargs = 0 })
                original(client, bufnr)
            end,
        })
    end
end

return M
