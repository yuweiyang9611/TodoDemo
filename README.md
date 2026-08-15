# TodoDemo

用于学习全栈开发的 Todo 示例，后端通过 SignalR 将变更实时推送给 Web 与 Flutter 客户端。

## 仓库迁移说明

本仓库由早期的私有仓库迁移重建。由于旧仓库的提交元数据、PR 等历史信息会暴露个人隐私，迁移时已删除旧私有仓库，并放弃其全部提交、分支和 PR 历史。本仓库从新的根提交重新开始。

## 项目结构

- `TodoDemo/`：ASP.NET Core Web API 与 SignalR Hub
- `TodoDemo/web/`：Vite + React + TypeScript 客户端
- `TodoDemo/app/`：Flutter 跨平台客户端

## Git hooks

在新设备克隆本仓库后，请按照 [GIT_HOOKS.md](GIT_HOOKS.md) 启用提交与推送前的邮箱保护 hooks。
## 验证

```powershell
dotnet build TodoDemo.slnx
npm --prefix TodoDemo/web ci
npm --prefix TodoDemo/web run build
flutter test TodoDemo/app
```