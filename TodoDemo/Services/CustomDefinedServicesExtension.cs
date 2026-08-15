namespace TodoDemo.Services;

public static class CustomDefinedServicesExtension
{
    public static IServiceCollection AddGetInfosServices(this IServiceCollection services)
    {
        services.AddSingleton<GetInfos>();
        return services;
    }
}
