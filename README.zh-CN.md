# session.nvim

基于原生 `:mksession` 和 `:source` 的轻量 Neovim 项目会话管理器。

[English](README.md)

## 功能

- 以项目根目录和可选名称管理多个会话。
- 使用 SHA-256 根目录哈希命名文件，并在 Vimscript 注释中保存可读元数据。
- 支持选择最近会话、任意已保存会话，以及可选的启动恢复。
- 支持退出自动保存和切换会话前自动保存。
- 发现会话时只读取元数据，不执行会话文件。
- 完全依赖 Neovim 原生 session 格式，并遵循当前 `sessionoptions`。

## 环境要求

- Neovim 0.12 或更新版本。
- 无第三方运行时依赖。

## 安装

Canonical 仓库位于 Codeberg：<https://codeberg.org/aevre/session.nvim>。

```lua
{
  "https://codeberg.org/aevre/session.nvim",
  opts = {},
}
```

`plugin/session.lua` 会以默认值初始化插件。插件管理器之后调用 `setup(opts)` 可以安全地覆盖默认配置。

## 配置

```lua
require("session").setup({
  dir = vim.fn.stdpath("state") .. "/sessions",
  autosave = true,
  autosave_on_switch = false,
  auto_restore = false,
})
```

- `dir`：session 文件存储目录。
- `autosave`：Neovim 退出前保存当前活动会话；没有活动会话时保存当前项目的默认会话。
- `autosave_on_switch`：加载另一个会话前保存当前活动会话。
- `auto_restore`：启动时恢复与启动文件或启动目录最匹配的会话；带文件参数启动时跳过。

项目根目录按以下顺序识别：包含当前文件的最深 LSP workspace、Git 根目录、Neovim 启动目录。保存或加载后，活动会话的身份保持不变，不受后续 `:cd` 影响。

会话由项目根目录和可选名称共同标识。省略名称时使用 `default`。名称只能包含字母、数字、`.`、`_` 和 `-`，且不能为 `.` 或 `..`。

## Lua API

- `save(name?, force?)`：保存当前 workspace 并将其设为活动会话；仅当 `force` 为 `true` 时覆盖已有会话。
- `load(name?)`：加载当前项目的默认或命名会话。
- `select()`：通过 `vim.ui.select()` 选择任意已保存会话。
- `last()`：加载最后修改的会话。
- `list()`：按修改时间倒序返回 `{ path, root, name }` 元数据记录。
- `active()`：返回当前活动会话记录，没有时返回 `nil`。

加载会话前，如果存在已修改的具名文件 buffer，插件会请求确认。执行原生 session 文件后，插件会将工作目录设为记录的项目根目录。

## 命令

- `:SessionSelect`
- `:SessionLast`
- `:SessionSave[!] [name]`
- `:SessionLoad [name]`

`:SessionSave!` 中的 `!` 允许覆盖已有命名会话。

## 原生 Session 行为

插件不实现独立的 buffer、窗口或编辑器状态序列化。保存结果由当前 `vim.o.sessionoptions` 决定。需要排除特殊 buffer 或目录参数时，应在对应插件或用户配置中处理，而不是让 session 管理器解析和重写生成的 Vimscript。

## 开发

在仓库根目录运行完整检查：

```sh
make check
```

该命令执行 Stylua 格式检查、Selene 静态检查和 headless session 测试。LuaLS 检查可单独运行：

```sh
lua-language-server --check . --checklevel=Warning
```

目录职责如下：

- `plugin/session.lua`：Neovim runtime 自动加载入口，仅负责带 guard 的默认初始化。
- `lua/session/init.lua`：公共 API 与生命周期 autocmd。
- `lua/session/config.lua`：配置默认值与合并。
- `lua/session/project.lua`：项目根目录识别。
- `lua/session/storage.lua`：文件名、元数据和会话列表。
- `lua/session/manager.lua`：保存、加载、选择与自动化流程。
- `lua/session/commands.lua`：Ex 命令。
- `lua/session/types.lua`：共享 LuaLS 类型。

`setup()` 必须支持 runtime 入口先以默认值调用、插件管理器随后以用户配置再次调用。`plugin/` 中不得放置业务逻辑。
