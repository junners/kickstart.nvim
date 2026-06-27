# jun.nvim

Personal Neovim config with a small Lua module tree, `lazy.nvim` for plugins, and `mise` as the only runtime tool resolver.

## Install

```bash
git clone git@github.com:junners/kickstart.nvim.git ~/.config/nvim
```

## Tooling Contract

- Plugins are declared only through `lazy.nvim`.
- LSP servers and formatters are resolved only through `mise`.
- Project-local `mise.toml` takes priority when present.
- If a project has no local `mise.toml`, Neovim falls back to the active global `mise` environment instead of falling back to raw `PATH`.
- If a required tool is missing from the relevant `mise` environment, Neovim warns instead of silently falling back to `PATH`.

Use `:checkhealth config` to inspect the local environment and the current project's `mise` tool availability.
