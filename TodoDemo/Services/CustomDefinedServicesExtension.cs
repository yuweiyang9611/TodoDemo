namespace TodoDemo.Services;

public static class CustomDefinedServicesExtension
{
    public static IServiceCollection AddGetInfosServices(this IServiceCollection services)
    {
        services.AddSingleton<GetInfos>(provider =>
        {
            var logger = provider.GetService<ILogger<GetInfos>>() ?? throw new NullReferenceException();
            return new GetInfos(logger);
        });
        return services;
    }
}