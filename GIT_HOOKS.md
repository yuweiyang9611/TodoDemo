# 启用 Git hooks

Git 不会在克隆仓库时自动启用版本库中的自定义 hooks。每次在新设备上克隆本项目后，需要为该克隆执行一次启用脚本。

## 自动启用（推荐）

在项目根目录使用 Windows PowerShell 运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\setup-git-hooks.ps1
```

如果使用 PowerShell 7，也可以运行：

```powershell
pwsh -NoProfile -File ./setup-git-hooks.ps1
```

脚本可以重复执行，只修改当前克隆的本地 Git 配置，不会修改全局 Git 配置。它会：

- 将 `core.hooksPath` 设置为 `.githooks`；
- 将当前仓库的提交邮箱设置为 GitHub noreply 邮箱；
- 启用 `user.useConfigOnly`，防止 Git 猜测其他邮箱；
- 检查 `pre-commit` 和 `pre-push` 是否存在。

## 验证

```powershell
git config --local --get core.hooksPath
git config --local --get user.email
git config --local --get user.useConfigOnly
```

预期输出依次为：

```text
.githooks
91787866+yuweiyang9611@users.noreply.github.com
true
```

启用后，提交或推送中只要 author 或 committer 不是上述 noreply 邮箱，就会被 hooks 阻止。

GitHub 上的 push 和 pull request 还会运行 `.github/workflows/privacy.yml`。该检查会：

- 拒绝 author 或 committer 未使用 GitHub noreply 邮箱的新增提交；
- 扫描 Git 跟踪的文本文件，拒绝其中的非 noreply 邮箱；
- 发现问题时只输出文件名和行号，不在日志中再次显示邮箱内容。

本地可以提前运行同一份内容扫描：

```powershell
py -3 ./scripts/check_email_privacy.py
```

在 macOS、Linux 或已将 Python 加入 `PATH` 的环境中，可将 `py -3` 换成 `python3`。

## 手动启用

如果不运行脚本，也可以在项目根目录执行：

```powershell
git config --local core.hooksPath .githooks
git config --local user.name yuweiyang9611
git config --local user.email 91787866+yuweiyang9611@users.noreply.github.com
git config --local user.useConfigOnly true
```