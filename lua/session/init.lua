local Config = require("session.config")
local Commands = require("session.commands")
local Manager = require("session.manager")

---@class session.Api
---@field setup fun(opts?: session.Config)
---@field save fun(name?: session.Name, force?: boolean): session.SaveResult
---@field load fun(name?: session.Name): session.LoadResult
---@field delete fun(name?: session.Name, force?: boolean): session.DeleteResult
---@field rename fun(name: session.Name, new_name: string): session.RenameResult
---@field select fun()
---@field last fun(): session.LoadResult
---@field list fun(): session.Record[]
---@field active fun(): session.Record?
local M = {}

---Configure session.nvim and register its lifecycle hooks and commands.
---@param opts? session.Config
function M.setup(opts)
	local config = Config.setup(opts)
	local group = vim.api.nvim_create_augroup("session.nvim", { clear = true })

	if config.autosave then
		vim.api.nvim_create_autocmd("VimLeavePre", {
			group = group,
			callback = Manager.save_on_exit,
		})
	end
	if config.auto_restore then
		vim.api.nvim_create_autocmd("VimEnter", {
			group = group,
			once = true,
			callback = Manager.restore_startup,
		})
	end

	Commands.setup(Manager)
end

M.save = Manager.save
M.load = Manager.load
M.delete = Manager.delete
M.rename = Manager.rename
M.select = Manager.select
M.last = Manager.last
M.list = Manager.list
M.active = Manager.active

return M
