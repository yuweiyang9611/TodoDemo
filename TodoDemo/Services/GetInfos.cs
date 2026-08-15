using System.Runtime.InteropServices;
using Microsoft.Win32;
using TodoDemo.DTOs;

namespace TodoDemo.Services;

public sealed class GetInfos(ILogger<GetInfos> logger)
{
    public SystemInfoDto GetSystemInfos()
    {
        // 运行时 & OS 信息
        var dotnetVersion = RuntimeInformation.FrameworkDescription; // e.g. ".NET 10.0.0"
        var clrVersion = Environment.Version.ToString(); // e.g. "10.0.0"
        var osDescription = RuntimeInformation.OSDescription; // e.g. "Microsoft Windows 10.0.26200"
        var osArchitecture = RuntimeInformation.OSArchitecture.ToString();
        var processArchitecture = RuntimeInformation.ProcessArchitecture.ToString();
        var runtimeIdentifier = RuntimeInformation.RuntimeIdentifier; // e.g. "win-x64", "linux-x64"
        var systemInfo = new SystemInfoDto
        {
            DotnetVersion = dotnetVersion,
            ClrVersion = clrVersion,
            OsDescription = osDescription,
            OsArchitecture = osArchitecture,
            ProcessArchitecture = processArchitecture,
            RuntimeIdentifier = runtimeIdentifier,
            WindowsInfo = GetWindowsInfo(),
            TimeInfoDto = GetTimeInfo()
        };
        return systemInfo;
    }

    private static TimeInfoDto GetTimeInfo()
    {
        // 时间 & 时区信息
        var now = DateTimeOffset.Now;
        var tz = TimeZoneInfo.Local;

        var localTime = now.ToString("yyyy-MM-dd HH:mm:ss zzz"); // 带偏移
        var utcTime = now.UtcDateTime.ToString("yyyy-MM-dd HH:mm:ss 'UTC'");
        var utcOffset = now.ToString("zzz"); // "+09:00" 这种格式
        var timeZoneId = tz.Id; // Windows: "Tokyo Standard Time", Linux: "Asia/Tokyo"
        var timeZoneDisplayName = tz.DisplayName;

        return new TimeInfoDto
        {
            LocalTime = localTime,
            UtcTime = utcTime,
            TimeZoneId = timeZoneId,
            TimeZoneDisplayName = timeZoneDisplayName,
            UtcOffset = utcOffset
        };
    }

    private WindowsProductNameDto? GetWindowsInfo()
    {
        if (!RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
            return null;

        try
        {
            using var key = Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Microsoft\Windows NT\CurrentVersion");
            // var productName = key?.GetValue("ProductName")?.ToString(); // 获取不到正确的名称，获取到的还是win10
            var displayVersion = key?.GetValue("DisplayVersion")?.ToString(); // 例如 "25H2"
            var currentBuild = key?.GetValue("CurrentBuild")?.ToString(); // 例如 "26200"
            var editionId = key?.GetValue("EditionID")?.ToString(); // "Professional"
            return new WindowsProductNameDto
            {
                ProductName = GetWindowsProductName(),
                DisplayVersion = displayVersion,
                CurrentBuild = currentBuild,
                EditionId = editionId,
            };
        }
        catch (Exception exception)
        {
            logger.LogWarning(exception, "Unable to read Windows version information from the registry.");
            return null;
        }
    }

    private string? GetWindowsProductName()
    {
        try
        {
            var pointer = BrandingFormatString("%WINDOWS_LONG%");
            if (pointer == IntPtr.Zero)
                return null;

            try
            {
                return Marshal.PtrToStringUni(pointer);
            }
            finally
            {
                // BrandingFormatString uses GlobalAlloc; GlobalFree returns zero on success.
                if (GlobalFree(pointer) != IntPtr.Zero)
                {
                    logger.LogWarning("Unable to release memory returned by BrandingFormatString.");
                }
            }
        }
        catch (Exception exception)
        {
            logger.LogWarning(exception, "Unable to read the Windows product name.");
            return null;
        }
    }

    /* SYSLIB1054：推荐使用 LibraryImport 替代 DllImport，以便在编译时生成封送代码，但该方法需要unsafe上下文  */
#pragma warning disable SYSLIB1054
    [DllImport("winbrand.dll", CharSet = CharSet.Unicode)]
    private static extern IntPtr BrandingFormatString(string format);

    [DllImport("kernel32.dll", SetLastError = false)]
    private static extern IntPtr GlobalFree(IntPtr hMem);
#pragma warning restore SYSLIB1054
    /* 恢复 SYSLIB1054 */
}