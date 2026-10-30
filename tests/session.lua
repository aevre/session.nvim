local test_file = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p")
local tmp = vim.fn.tempname()
if vim.env.SESSION_AUTOSAVE_CHILD then
	local session = require("session")
	session.setup({ dir = vim.env.SESSION_TEST_DIR, autosave = vim.env.SESSION_AUTOSAVE_ENABLED == "1" })
	vim.cmd("edit " .. vim.fn.fnameescape(vim.env.SESSION_TEST_DIR .. "/project/one.txt"))
	return
end

vim.fn.mkdir(tmp .. "/project/.git", "p")
vim.fn.mkdir(tmp .. "/sessions", "p")
vim.fn.writefile({ "one" }, tmp .. "/project/one.txt")
vim.cmd("cd " .. vim.fn.fnameescape(tmp .. "/project"))
vim.cmd("edit " .. vim.fn.fnameescape(tmp .. "/project/one.txt"))
local session = require("session")
session.setup({ dir = tmp .. "/sessions", autosave = false })
session.setup({ dir = tmp .. "/sessions", autosave = false })
assert(vim.fn.exists(":SessionSave") == 2, "setup should support plugin defaults followed by user options")

local Storage = require("session.storage")
local root_path = Storage.path(tmp .. "/sessions", "/", "root")
assert(root_path:match(vim.fn.sha256("/") .. "%-%-root%.vim$"), "session storage should preserve the filesystem root")

local path, err = session.save("review")
assert(path, err)
assert(path:match("%x+%-%-review%.vim$"))
assert(#session.list() == 1)
assert(session.list()[1].root == tmp .. "/project")
assert(session.active().name == "review")
local duplicate, duplicate_err = session.save("review")
assert(not duplicate and duplicate_err == "session already exists")
vim.fn.mkdir(tmp .. "/other", "p")
vim.cmd.cd(tmp .. "/other")
assert(session.save("review", true) == path)
assert(vim.fn.getcwd() == tmp .. "/other", "saving must preserve the current working directory")

vim.api.nvim_buf_set_lines(0, 0, -1, false, { "changed" })
vim.bo.modified = false
local default_path = assert(session.save(nil))
assert(default_path ~= path)
assert(session.list()[1].name == "default")
assert(session.load("review"))
assert(session.active().name == "review")
assert(vim.fn.getcwd() == tmp .. "/project", "loading must use the session root instead of its saved cwd")

local last = session.last()
assert(last)
assert(session.list()[1].path == path or session.list()[1].path == default_path)

local special_dir = tmp .. "/[sessions]"
session.setup({ dir = special_dir, autosave = false })
local special_path = assert(session.save("special"))
assert(special_path and #session.list() == 1, "session listing should support glob characters in storage paths")

local auto_dir = tmp .. "/autosave"
vim.fn.mkdir(auto_dir .. "/project/.git", "p")
vim.fn.writefile({ "autosaved" }, auto_dir .. "/project/one.txt")
local nvim = vim.v.progpath
local command = {
	nvim,
	"--clean",
	"--headless",
	"-u",
	"NONE",
	"--cmd",
	"set rtp^=" .. vim.fn.fnameescape(vim.fn.fnamemodify(test_file, ":h:h")),
	"-l",
	test_file,
}
local env = {
	SESSION_AUTOSAVE_CHILD = "1",
	SESSION_AUTOSAVE_ENABLED = "1",
	SESSION_TEST_DIR = auto_dir .. "/sessions",
}
local result = vim.system(command, { env = env }):wait()
assert(result.code == 0, result.stderr)
local auto_files = vim.fn.glob(auto_dir .. "/sessions/*.vim", false, true)
assert(#auto_files == 1, "VimLeavePre did not write the active default session")
local autosave_off = vim.system(command, {
	env = vim.tbl_extend("force", env, {
		SESSION_AUTOSAVE_ENABLED = "0",
		SESSION_TEST_DIR = auto_dir .. "/disabled",
	}),
}):wait()
assert(autosave_off.code == 0, autosave_off.stderr)
assert(
	#vim.fn.glob(auto_dir .. "/disabled/sessions/*.vim", false, true) == 0,
	"autosave=false should not write a session"
)
print("session.nvim tests passed")
