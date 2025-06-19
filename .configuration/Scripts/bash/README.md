# Azure App Registration Script

## Overview

This script automates the creation of Azure AD app registrations with service principals for APIM (API Management) authentication. It follows bash scripting best practices with comprehensive error handling, logging, and security considerations.

## Features

- ✅ **Comprehensive Error Handling**: Proper error trapping and graceful failure handling
- ✅ **Detailed Logging**: Timestamped logs with different severity levels
- ✅ **Input Validation**: Validates environment variables and Azure CLI authentication
- ✅ **Idempotent Operations**: Safe to run multiple times without creating duplicates
- ✅ **Security Best Practices**: Secure handling of client secrets and credentials
- ✅ **Retry Logic**: Automatic retries for transient failures
- ✅ **Modular Design**: Well-organized functions for maintainability

## Prerequisites

1. **Azure CLI**: Installed and authenticated
   ```bash
   # Install Azure CLI (if not already installed)
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
   
   # Login to Azure
   az login
   ```

2. **Environment File**: Create `./envName/.env` with required variables

## Environment Variables

Create a `.env` file in the `./envName/` directory with the following variables:

```bash
# Required Variables
APP_NAME=your-app-name
REDIRECT_URI=https://your-domain.com/callback

# Optional Variables (defaults shown)
ROLE_NAME=Reader
```

### Variable Descriptions

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `APP_NAME` | Display name for the Azure AD app registration | Yes | - |
| `REDIRECT_URI` | OAuth redirect URI (must be HTTPS) | Yes | - |
| `ROLE_NAME` | Azure role to assign to the service principal | No | Reader |

## Usage

### Basic Usage

```bash
# Make the script executable
chmod +x ./src/Scripts/appRegistration.sh

# Run the script
./src/Scripts/appRegistration.sh
```

### Example .env File

```bash
# Example configuration for APIM authentication
APP_NAME=MyAPIM-AuthApp
REDIRECT_URI=https://myapi.example.com/auth/callback
ROLE_NAME=API Management Service Contributor
```

## Script Output

The script provides detailed output including:

1. **Real-time Logging**: Timestamped log messages with severity levels
2. **Azure Resource Details**: Client ID, Tenant ID, Subscription ID
3. **Security Information**: Client secret (shown only once)
4. **Log File**: Persistent log file (`app_registration.log`)

### Sample Output

```
[2025-06-19 10:30:15] [INFO] Starting Azure App Registration setup...
[2025-06-19 10:30:15] [SUCCESS] Azure CLI is available and authenticated
[2025-06-19 10:30:16] [SUCCESS] Environment variables loaded from ./envName/.env
[2025-06-19 10:30:16] [SUCCESS] All required variables are valid
[2025-06-19 10:30:17] [SUCCESS] Azure information retrieved
[2025-06-19 10:30:18] [SUCCESS] App registration created successfully
[2025-06-19 10:30:20] [SUCCESS] Service principal created successfully
[2025-06-19 10:30:22] [SUCCESS] Role 'Reader' assigned successfully
[2025-06-19 10:30:23] [SUCCESS] Client secret created successfully

==========================================
 AZURE APP REGISTRATION DETAILS
==========================================
App Name:        MyAPIM-AuthApp
Client ID:       12345678-1234-1234-1234-123456789012
Tenant ID:       87654321-4321-4321-4321-210987654321
Subscription ID: 11111111-2222-3333-4444-555555555555
Role Assigned:   Reader
Redirect URI:    https://myapi.example.com/auth/callback

CLIENT SECRET:   your-generated-secret-here

==========================================
 SECURITY NOTICE
==========================================
⚠️  IMPORTANT: The client secret above is shown only once.
   Store it securely in your key vault or secure configuration.
```

## Error Handling

The script includes comprehensive error handling:

- **Azure CLI Validation**: Checks installation and authentication
- **Environment Variable Validation**: Ensures all required variables are present
- **Azure Resource Validation**: Verifies successful creation of resources
- **Retry Logic**: Automatic retries for transient failures
- **Graceful Failure**: Detailed error messages with exit codes

## Security Considerations

1. **Client Secret Security**: 
   - Client secrets are shown only once
   - Consider using Azure Key Vault for storage
   - GPG encryption option suggested if available

2. **Environment File Security**:
   - Ensure `.env` files are not committed to version control
   - Use appropriate file permissions (600)

3. **Logging Security**:
   - Sensitive information is not logged to files
   - Log files should be secured appropriately

## Troubleshooting

### Common Issues

1. **Azure CLI Not Authenticated**
   ```bash
   # Solution: Login to Azure
   az login
   ```

2. **Missing Environment Variables**
   ```bash
   # Solution: Check your .env file
   cat ./envName/.env
   ```

3. **Permission Errors**
   ```bash
   # Solution: Ensure you have appropriate Azure permissions
   az role assignment list --assignee $(az account show --query user.name -o tsv)
   ```

4. **App Registration Already Exists**
   - The script handles this gracefully and will update the existing registration

### Log File Analysis

Check the log file for detailed information:
```bash
cat ./src/Scripts/app_registration.log
```

## Best Practices Applied

### Bash Scripting Best Practices

1. **Strict Mode**: `set -euo pipefail`
2. **Secure IFS**: `IFS=$'\n\t'`
3. **Readonly Variables**: `readonly SCRIPT_NAME`
4. **Error Trapping**: `trap 'error_handler ${LINENO}' ERR`
5. **Function Organization**: Modular, single-purpose functions
6. **Input Validation**: Comprehensive validation of all inputs
7. **Consistent Logging**: Timestamped, severity-based logging
8. **Cleanup Handling**: Proper cleanup on exit

### Security Best Practices

1. **Secure Variable Handling**: Safe loading of environment variables
2. **Secret Management**: Secure handling of client secrets
3. **Error Information**: Detailed but non-sensitive error messages
4. **File Permissions**: Guidance on securing configuration files

## File Structure

```
src/
├── Scripts/
│   ├── appRegistration.sh          # Main script (corrected name)
│   ├── appRegitsration.sh          # Original script (typo in name)
│   ├── app_registration.log        # Generated log file
│   └── README.md                   # This documentation
└── envName/
    └── .env                        # Environment configuration
```

## Contributing

When modifying this script, please maintain:

1. **Consistent Coding Style**: Follow the established patterns
2. **Comprehensive Logging**: Add appropriate log messages
3. **Error Handling**: Ensure proper error handling for new functionality
4. **Documentation**: Update this README for any changes
5. **Testing**: Test with various scenarios and edge cases

## Version History

- **v1.0**: Initial release with comprehensive error handling and logging
  - Azure app registration creation
  - Service principal creation
  - Role assignment
  - Client secret generation
  - Comprehensive logging and error handling
