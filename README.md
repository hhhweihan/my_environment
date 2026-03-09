# my_environment

轻量化环境初始化脚本，目标是一次执行完成开发终端基础配置。

## 功能

- 安装基础工具：`git`、`zsh`、`tmux`、`curl`、`nodejs`、`npm`
- 可选配置 Git：`user.name`、`user.email`
- 安装 Oh My Zsh 与常用插件
- 生成基础 `~/.tmux.conf`
- 检测并可选安装：`claude-code`、`opencode`
- 可选写入 API Key：`ANTHROPIC_API_KEY`、`OPENCODE_API_KEY`
- 将默认 shell 切换为 `zsh`（如当前不是）

## 使用方式

在 `my_env` 目录执行：

```bash
bash install.sh
```

## 交互流程

脚本执行时会依次询问：

1. 是否配置 Git 用户信息
2. 若选择配置，输入 `git user.name` 与 `git user.email`
3. 是否安装 `claude-code`
4. 是否安装 `opencode`
5. 是否写入 `ANTHROPIC_API_KEY`
6. 是否写入 `OPENCODE_API_KEY`

## 执行结果

- `~/.zshrc` 会被重写，并自动备份旧文件为 `~/.zshrc.bak.<timestamp>`
- `~/.tmux.conf` 会被重写，并自动备份旧文件为 `~/.tmux.conf.bak.<timestamp>`
- API Key 会写入 `~/.zshrc`

## 生效配置

执行完成后，使用以下命令加载新配置：

```bash
exec zsh
```

或重新打开终端会话。

## 常见问题

- 提示 `sudo is required`：请安装 `sudo` 或使用 root 用户执行
- `chsh` 修改默认 shell 失败：按脚本提示手动执行 `chsh -s $(which zsh)`
