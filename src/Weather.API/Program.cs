using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.Identity.Web;
using Microsoft.IdentityModel.Logging;
using Microsoft.IdentityModel.Tokens;
using Swashbuckle.AspNetCore.Swagger;

var builder = WebApplication.CreateBuilder(args);

// Enable detailed identity logs (dev only)
IdentityModelEventSource.ShowPII = true;

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme);
    //.AddMicrosoftIdentityWebApi(builder.Configuration.GetSection("AzureAd"));


// Swagger
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Add auth and controllers
builder.Services.AddAuthorization();
builder.Services.AddControllers();

// Optional: Service discovery or health checks
builder.AddServiceDefaults();

var app = builder.Build();

app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapDefaultEndpoints();

// Swagger UI setup
app.UseSwagger();
app.UseSwaggerUI();

app.Run();
