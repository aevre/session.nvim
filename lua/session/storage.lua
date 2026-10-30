local M = {}
local uv = vim.uv or vim.loop
local metadata_prefix = '" session.nvim: '

local function normalize(path)
	local normalized = vim.fs.normalize(path)
	return normalized ~= "/" and normalized:gsub("/$", "") or normalized
end

---Validate and normalize an optional user-provided name.
---@param name session.Name
---@return string
function M.name(name)
	if name == nil or name == "" then
		return "default"
	end
	assert(
		type(name) == "string" and name:match("^[%w_.%-]+$") and name ~= "." and name ~= "..",
		"invalid session name"
	)
	return name
end

---Build a stable file path from the project root hash and validated name.
---@param dir string
---@param root string
---@param name session.Name
---@return string
function M.path(dir, root, name)
	return dir .. "/" .. vim.fn.sha256(normalize(root)) .. "--" .. M.name(name) .. ".vim"
end

---Read the marker without sourcing executable session contents.
---@param path string
---@return session.Record?
function M.read(path)
	local ok, lines = pcall(vim.fn.readfile, path, "", 8)
	if not ok then
		return
	end
	for _, line in ipairs(lines) do
		if line:sub(1, #metadata_prefix) == metadata_prefix then
			local decoded, data = pcall(vim.json.decode, line:sub(#metadata_prefix + 1))
			if decoded and type(data) == "table" and type(data.root) == "string" and type(data.name) == "string" then
				local valid_name, normalized = pcall(M.name, data.name)
				if valid_name and normalized == data.name then
					return { path = path, root = normalize(data.root), name = data.name }
				end
			end
		end
	end
end

---List valid plugin sessions, newest first.
---@param dir string
---@return session.Record[]
function M.list(dir)
	local result = {}
	for name, kind in vim.fs.dir(dir) do
		if kind == "file" and name:match("%.vim$") then
			local path = dir .. "/" .. name
			local record = M.read(path)
			if record then
				result[#result + 1] = record
			end
		end
	end
	table.sort(result, function(a, b)
		local a_stat, b_stat = uv.fs_stat(a.path), uv.fs_stat(b.path)
		local a_time = a_stat and a_stat.mtime.sec or 0
		local b_time = b_stat and b_stat.mtime.sec or 0
		return a_time == b_time and a.path < b.path or a_time > b_time
	end)
	return result
end

---Write metadata as a Vimscript comment, preserving native :source behavior.
---@param path string
---@param root string
---@param name string
---@return true?, string?
function M.write_metadata(path, root, name)
	local lines = vim.fn.readfile(path)
	local metadata = metadata_prefix .. vim.json.encode({ root = normalize(root), name = name })
	if lines[1] and lines[1]:sub(1, #metadata_prefix) == metadata_prefix then
		lines[1] = metadata
	else
		table.insert(lines, 1, metadata)
	end
	local ok, result = pcall(vim.fn.writefile, lines, path)
	if not ok then
		return nil, result
	end
	if result ~= 0 then
		return nil, "unable to write session metadata"
	end
	return true
end

return M
