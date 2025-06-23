using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.Identity.Web;
using Microsoft.IdentityModel.Logging;
using Microsoft.IdentityModel.Tokens;

var builder = WebApplication.CreateBuilder(args);

// Habilita logs detalhados (dev only)
IdentityModelEventSource.ShowPII = true;

// Configuração via appsettings.json
var azureAdConfig = builder.Configuration.GetSection("AzureAd");
var validAudience = azureAdConfig["Audience"] ?? azureAdConfig["ClientId"];

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddMicrosoftIdentityWebApi(options =>
    {
        azureAdConfig.Bind(options);

        // Validação explícita do audience
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateAudience = true,
            ValidAudience = validAudience,
            ValidateIssuer = true
        };

        // Log de falha de autenticação
        options.Events = new JwtBearerEvents
        {
            OnAuthenticationFailed = context =>
            {
                Console.WriteLine($"Invalid Token: {context.Exception.Message}");
                return Task.CompletedTask;
            }
        };
    },
    options => azureAdConfig.Bind(options));

builder.Services.AddAuthorization();
builder.Services.AddControllers();
builder.AddServiceDefaults(); // Suporte para Service Discovery, Health Checks etc.

var app = builder.Build();

app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapDefaultEndpoints();

app.Run();
