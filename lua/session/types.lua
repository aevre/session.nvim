---@class session.Config
---@field dir? string Session storage directory.
---@field autosave? boolean Save the active session before Neovim exits.
---@field autosave_on_switch? boolean Save the current session before loading another.
---@field auto_restore? boolean Restore the best matching session on startup.

---@class session.Record
---@field path string Absolute path to the session file.
---@field root string Project root recorded when the session was saved.
---@field name string Session name, or `default`.

---@alias session.Name string|nil
---@alias session.SaveResult string?, string?
---@alias session.LoadResult boolean?, string?
---@alias session.DeleteResult boolean?, string?
---@alias session.RenameResult string?, string?

---@class session.Manager
---@field save fun(name?: session.Name, force?: boolean): session.SaveResult
---@field load fun(name?: session.Name): session.LoadResult
---@field delete fun(name?: session.Name, force?: boolean): session.DeleteResult
---@field rename fun(name: session.Name, new_name: string): session.RenameResult
---@field delete_select fun(force?: boolean)
---@field rename_select fun()
---@field select fun()
---@field last fun(): session.LoadResult

---@class session.Api
---@field setup fun(opts?: session.Config)
---@field save fun(name?: session.Name, force?: boolean): session.SaveResult
---@field load fun(name?: session.Name): session.LoadResult
---@field delete fun(name?: session.Name, force?: boolean): session.DeleteResult
---@field rename fun(name: session.Name, new_name: string): session.RenameResult
---@field select fun()
---@field last fun(): boolean?, string?
---@field list fun(): session.Record[]
---@field active fun(): session.Record?

return {}
