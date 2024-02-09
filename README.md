# tsserver-workspace-linter.nvim

Enables the `:Tsc` command in buffers where tsserver has attached.

The command runs tsc in the root_dir of tsserver and appends any result to the quickfix list.

Using Lazy:

```lua
{
    "stornquist/tsserver-workspace-linter.nvim",
    event = "VeryLazy",
    dependencies = { "neovim/nvim-lspconfig" },
    opts = {},
}
```
