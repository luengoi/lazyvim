local M = {}

function M.find_configuration_file(filename, startpath)
  return vim.fs.find(filename, { path = startpath, upward = true })[1]
end

-- Linter configuration
M.swiftlint = {
  cmd = "swiftlint",
  stdin = true,
  args = {
    "lint",
    "--use-stdin",
    "--config",
    M.find_configuration_file(".swiftlint.yml", vim.api.nvim_buf_get_name(0)),
    "-",
  },
  stream = "stdout",
  ignore_exitcode = true,
  parser = require("lint.parser").from_pattern(
    "[^:]+:(%d+):(%d+): (%w+): (.+)",
    { "lnum", "col", "severity", "message" },
    {
      ["error"] = vim.diagnostic.severity.ERROR,
      ["warning"] = vim.diagnostic.severity.WARN,
    },
    { ["source"] = "swiftlint" }
  ),
  condition = function(ctx)
    -- TODO: Check ignore pattern in .swiftlint.yml file
    return vim.fs.find(".swiftlint.yml", { path = ctx.filename, upward = true })[1]
  end,
}

return {
  -- Treesitter configuration
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "swift" })
    end,
  },

  -- Setup sourcekit language server
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
    },
    opts = {
      servers = {
        sourcekit = {
          on_attach = function(_, bufnr)
            local which_key = require("which-key")
            which_key.register({
              ["<leader>d"] = {
                function()
                  vim.diagnostic.open_float()
                end,
                "Show line diagnostics",
              },
              ["K"] = {
                function()
                  vim.lsp.buf.hover()
                end,
                "Show documentation",
              },
            }, { mode = "n", buffer = bufnr })
          end,
          cmd = {
            "/Library/Developer/CommandLineTools/usr/bin/sourcekit-lsp",
          },
          root_dir = function(filename, _)
            return require("lspconfig.util").root_pattern("Package.swift")(filename)
          end,
        },
      },
    },
  },

  -- Setup linting
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        swift = { "swiftlint" },
      },
      linters = {
        swiftlint = M.swiftlint,
      },
    },
  },

  -- Setup formatting
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        swift = { "swiftformat" },
      },
      formatters = {
        swiftformat = {
          condition = function(ctx)
            return M.find_configuration_file(".swiftformat", ctx.filename)
          end,
        },
      },
    },
  },
}
