namespace TodoDemo.DTOs;

public class TimeInfoDto
{
    public string LocalTime { get; init; } = null!; // 本地时间（含偏移，如 "2025-11-16 23:41:36 +09:00"）
    public string UtcTime { get; init; } = null!; // UTC 时间
    public string TimeZoneId { get; init; } = null!; // 时区 ID（Windows: "Tokyo Standard Time"; Linux: "Asia/Tokyo"）
    public string TimeZoneDisplayName { get; init; } = null!; // 时区显示名称
    public string UtcOffset { get; init; } = null!; // 当前偏移（如 "+09:00"）
}