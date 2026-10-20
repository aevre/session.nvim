if vim.g.loaded_session_nvim then
	return
end
vim.g.loaded_session_nvim = true

require("session").setup()
