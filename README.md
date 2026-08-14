# TodoDemo

用于学习全栈开发的 Todo 示例，后端通过 SignalR 将变更实时推送给 Web 与 Flutter 客户端。

## 项目结构

- `TodoDemo/`：ASP.NET Core Web API 与 SignalR Hub
- `TodoDemo/web/`：Vite + React + TypeScript 客户端
- `TodoDemo/app/`：Flutter 跨平台客户端

## 验证

```powershell
dotnet build TodoDemo.slnx
npm --prefix TodoDemo/web ci
npm --prefix TodoDemo/web run build
flutter test TodoDemo/app
```
