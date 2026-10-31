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

Available on Codeberg: <https://codeberg.org/aevre/session.nvim> and GitHub: <https://github.com/aevre/session.nvim>.

```lua
{
  "https://github.com/aevre/session.nvim",
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
- `delete(force?)`: delete the active session; confirmation is skipped when `force` is `true`.
- `delete_select(force?)`: choose a session from the list and delete it.
- `rename(new_name)`: rename the active session without overwriting an existing session.
- `rename_select()`: choose a session from the list and enter its new name.
- `select()`: select any saved session through `vim.ui.select()`.
- `last()`: load the most recently modified session.
- `list()`: return `{ path, root, name }` metadata records, newest first.
- `active()`: return the active session record, or `nil`.

Before loading, the plugin asks for confirmation when named file buffers have unsaved changes. After sourcing the native session, it sets the working directory to the recorded project root.

## Commands

- `:SessionSelect`
- `:SessionLast`
- `:SessionInfo`
- `:SessionSave[!] [name]`
- `:SessionLoad [name]`
- `:SessionDelete[!]`
- `:SessionDeleteSelect[!]`
- `:SessionRename new_name`
- `:SessionRenameSelect`

`:SessionDelete` and `:SessionRename` operate on the active session. The `Select` variants choose a session from the saved-session list. `:SessionInfo` displays the active session's name, project root, and file path.

The `!` on `:SessionSave!` permits replacing an existing named session. The `!` on either delete command skips confirmation.

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
