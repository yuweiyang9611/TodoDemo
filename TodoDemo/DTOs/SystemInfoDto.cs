namespace TodoDemo.DTOs;

public class SystemInfoDto
{
    public string DotnetVersion { get; init; } = null!; // .NET 版本（如 ".NET 10.0.0"）
    public string ClrVersion { get; init; } = null!; // CLR 版本（如 "10.0.0"）
    public string OsDescription { get; init; } = null!; // 操作系统描述（RuntimeInformation.OSDescription）
    public string OsArchitecture { get; init; } = null!; // OS 架构（X64 / Arm64 等）
    public string ProcessArchitecture { get; init; } = null!; // 进程架构
    public string RuntimeIdentifier { get; init; } = null!; // 运行时 RID（如 "win-x64", "linux-x64"）

    // 仅在 Windows 下有意义，其它系统为 null
    public WindowsProductNameDto? WindowsInfo { get; init; } // "Windows 11 Pro" / "Windows 10 Pro" 等

    // 时间 / 时区相关
    public TimeInfoDto TimeInfoDto { get; init; } = null!;
}