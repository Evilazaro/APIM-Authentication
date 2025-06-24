var builder = DistributedApplication.CreateBuilder(args);

builder.AddProject<Projects.Weather_API>("weather-api");

builder.Build().Run();
