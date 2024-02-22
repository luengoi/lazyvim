return {
  "williamboman/mason.nvim",
  opts = {
    ensure_installed = {
      -- LSP
      "pyright",
      "rust-analyzer",
      -- linters
      "eslint_d",
      -- formatters
      "prettierd",
    },
  },
}
