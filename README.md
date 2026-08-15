# TodoDemo

一个用于学习全栈开发的 Todo 示例：ASP.NET Core 负责 REST API 和 SignalR，React/TypeScript 与 Flutter 共享同一数据契约并实时同步。

> 数据保存在内存中，服务重启后会清空。本项目适合本地学习，不应未经认证和持久化改造就直接部署为公开可写服务。

## 学习文档

请先阅读 [架构、设计思路与多语言最佳实践](docs/ARCHITECTURE_AND_BEST_PRACTICES.md)。文档包含数据流、REST/SignalR 分工、C#/TypeScript/Dart 对照、平台网络配置、测试方式和后续练习建议。

## 项目结构

- `TodoDemo/`：.NET 10 ASP.NET Core API 与 SignalR Hub
- `TodoDemo.Tests/`：MSTest 仓储并发与 CRUD 测试
- `TodoDemo/web/`：Vite + React + TypeScript 客户端
- `TodoDemo/app/`：Flutter 跨平台客户端
- `docs/`：项目设计与学习资料

## 快速启动

先启动后端：

```powershell
dotnet run --project TodoDemo/TodoDemo.csproj --launch-profile http
```

再启动 Web：

```powershell
npm --prefix TodoDemo/web ci
npm --prefix TodoDemo/web run dev
```

详细的 Flutter Desktop、Android Emulator 和 Flutter Web 启动参数见学习文档。

## 完整验证

```powershell
dotnet build TodoDemo.slnx --nologo
dotnet test --solution TodoDemo.slnx --no-restore
dotnet list TodoDemo/TodoDemo.csproj package --vulnerable --include-transitive

npm --prefix TodoDemo/web ci
npm --prefix TodoDemo/web run lint
npm --prefix TodoDemo/web run build
npm --prefix TodoDemo/web audit --omit=dev

Set-Location TodoDemo/app
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Git hooks 与邮箱隐私

在新设备克隆后，请按照 [GIT_HOOKS.md](GIT_HOOKS.md) 运行 `setup-git-hooks.ps1`，启用提交和推送前的私人邮箱保护。

## 仓库迁移说明

本仓库由早期的私有仓库迁移重建。由于旧仓库的提交元数据、PR 等历史信息会暴露个人隐私，迁移时已删除旧私有仓库，并放弃其全部提交、分支和 PR 历史。本仓库从新的根提交重新开始。
