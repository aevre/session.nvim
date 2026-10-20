# session.nvim

A small Neovim project-session manager built on native `:mksession` and `:source`.

[简体中文](README.zh-CN.md)

## Features

- Manage multiple sessions by project root and optional name.
- Use SHA-256 root hashes for filenames and readable metadata in a Vimscript comment.
- Select the latest session or any saved session, with optional startup restore.
- Autosave on exit and optionally before switching sessions.
- Read metadata without executing session files during discovery.
- Keep Neovim's native session format and respect the current `sessionoptions`.

## Requirements

- Neovim 0.12 or newer.
- No third-party runtime dependencies.

## Installation

The canonical repository is hosted on Codeberg: <https://codeberg.org/aevre/session.nvim>.

```lua
{
  "https://codeberg.org/aevre/session.nvim",
  opts = {},
}
```

`plugin/session.lua` initializes the plugin with defaults. A plugin manager can safely call `setup(opts)` afterward to apply user configuration.

## Configuration

```lua
require("session").setup({
  dir = vim.fn.stdpath("state") .. "/sessions",
  autosave = true,
  autosave_on_switch = false,
  auto_restore = false,
})
```

- `dir`: directory used for session files.
- `autosave`: save the active session before Neovim exits; without an active session, save the current project's default session.
- `autosave_on_switch`: save the active session before loading another one.
- `auto_restore`: restore the best match for the startup file or startup directory; skipped when Neovim starts with file arguments.

Project roots are identified in this order: the deepest LSP workspace containing the current file, the Git root, then Neovim's startup directory. Once a session is saved or loaded, its active identity stays fixed even if `:cd` changes the working directory.

A session is identified by project root and optional name. Omitting the name uses `default`. Names may contain letters, digits, `.`, `_`, and `-`, except `.` and `..`.

## Lua API

- `save(name?, force?)`: save the current workspace and activate it; existing sessions are overwritten only when `force` is `true`.
- `load(name?)`: load the current project's default or named session.
- `select()`: select any saved session through `vim.ui.select()`.
- `last()`: load the most recently modified session.
- `list()`: return `{ path, root, name }` metadata records, newest first.
- `active()`: return the active session record, or `nil`.

Before loading, the plugin asks for confirmation when named file buffers have unsaved changes.

## Commands

- `:SessionSelect`
- `:SessionLast`
- `:SessionSave[!] [name]`
- `:SessionLoad [name]`

The `!` on `:SessionSave!` permits replacing an existing named session.

## Native session behavior

The plugin does not implement separate buffer, window, or editor-state serialization. The current `vim.o.sessionoptions` controls what `:mksession` writes. Exclusions for special buffers or directory arguments belong in the responsible plugin or user configuration rather than in a parser that rewrites generated session Vimscript.

## Development

Run the complete local check from the repository root:

```sh
make check
```

This runs Stylua formatting checks, Selene, and the headless session test. Run LuaLS diagnostics separately:

```sh
lua-language-server --check . --checklevel=Warning
```

The repository layout is responsibility-based:

- `plugin/session.lua`: guarded Neovim runtime entrypoint for default setup.
- `lua/session/init.lua`: public API and lifecycle autocmds.
- `lua/session/config.lua`: defaults and option merging.
- `lua/session/project.lua`: project-root detection.
- `lua/session/storage.lua`: filenames, metadata, and session listing.
- `lua/session/manager.lua`: save, load, selection, and automation flows.
- `lua/session/commands.lua`: Ex commands.
- `lua/session/types.lua`: shared LuaLS types.

`setup()` must remain safe when the runtime entrypoint calls it with defaults before a plugin manager calls it again with user options. Keep business logic out of `plugin/`.
