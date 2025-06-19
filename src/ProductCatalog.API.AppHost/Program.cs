var builder = DistributedApplication.CreateBuilder(args);

builder.AddProject<Projects.ProductCatalog_API>("productcatalog-api");

builder.Build().Run();
