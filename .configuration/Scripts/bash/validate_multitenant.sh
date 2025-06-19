#!/bin/bash

#==============================================================================
# Azure App Registration Validation Script
#==============================================================================
# Description: Validates that an Azure AD app registration is properly 
#              configured for multitenant access
# Usage: ./validate_multitenant.sh <app-id>
#==============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  INFO: $*${NC}"
}

log_success() {
    echo -e "${GREEN}✅ SUCCESS: $*${NC}"
}

log_warn() {
    echo -e "${YELLOW}⚠️  WARNING: $*${NC}"
}

log_error() {
    echo -e "${RED}❌ ERROR: $*${NC}"
}

# Usage function
usage() {
    echo "Usage: $0 <app-id>"
    echo "       $0 --help"
    echo ""
    echo "Validates Azure AD app registration multitenant configuration"
    echo ""
    echo "Arguments:"
    echo "  app-id    The Application (Client) ID to validate"
    echo ""
    echo "Examples:"
    echo "  $0 12345678-1234-1234-1234-123456789012"
    echo "  $0 --help"
    exit 1
}

# Main validation function
validate_app_registration() {
    local app_id="$1"
    
    log_info "Validating app registration: $app_id"
    
    # Check if Azure CLI is available and authenticated
    if ! command -v az &> /dev/null; then
        log_error "Azure CLI is not installed"
        exit 1
    fi
    
    if ! az account show &> /dev/null; then
        log_error "Azure CLI is not authenticated. Please run 'az login' first"
        exit 1
    fi
    
    # Get app registration details
    log_info "Fetching app registration details..."
    
    local app_details
    app_details=$(az ad app show --id "$app_id" 2>/dev/null) || {
        log_error "Failed to find app registration with ID: $app_id"
        exit 1
    }
    
    # Extract key information
    local display_name=$(echo "$app_details" | jq -r '.displayName // "N/A"')
    local sign_in_audience=$(echo "$app_details" | jq -r '.signInAudience // "N/A"')
    local app_id_actual=$(echo "$app_details" | jq -r '.appId // "N/A"')
    local web_redirect_uris=$(echo "$app_details" | jq -r '.web.redirectUris[]? // empty' | tr '\n' ', ' | sed 's/,$//')
    
    # Display basic information
    echo ""
    echo "==========================================="
    echo " APP REGISTRATION DETAILS"
    echo "==========================================="
    echo "Display Name:     $display_name"
    echo "Application ID:   $app_id_actual"
    echo "Sign-in Audience: $sign_in_audience"
    echo "Redirect URIs:    ${web_redirect_uris:-"None configured"}"
    echo ""
    
    # Validate multitenant configuration
    echo "==========================================="
    echo " MULTITENANT VALIDATION"
    echo "==========================================="
    
    case "$sign_in_audience" in
        "AzureADMultipleOrgs")
            log_success "App is configured as MULTITENANT"
            log_success "Sign-in audience: Accounts in any organizational directory"
            ;;
        "AzureADMyOrg")
            log_warn "App is configured as SINGLE TENANT"
            log_warn "Only users from the home tenant can sign in"
            log_info "To make it multitenant, run: az ad app update --id $app_id --sign-in-audience AzureADMultipleOrgs"
            ;;
        "AzureADandPersonalMicrosoftAccount")
            log_info "App supports both organizational and personal accounts"
            log_info "This is broader than standard multitenant (includes personal Microsoft accounts)"
            ;;
        "PersonalMicrosoftAccount")
            log_warn "App only supports personal Microsoft accounts"
            log_warn "Organizational accounts cannot sign in"
            ;;
        *)
            log_error "Unknown sign-in audience: $sign_in_audience"
            ;;
    esac
    
    # Check for service principal
    echo ""
    echo "==========================================="
    echo " SERVICE PRINCIPAL VALIDATION"
    echo "==========================================="
    
    local sp_exists
    sp_exists=$(az ad sp list --filter "appId eq '$app_id'" --query "[0].id" -o tsv 2>/dev/null || echo "")
    
    if [[ -n "$sp_exists" ]]; then
        log_success "Service principal exists: $sp_exists"
    else
        log_warn "Service principal not found"
        log_info "To create one, run: az ad sp create --id $app_id"
    fi
    
    # Check redirect URIs
    echo ""
    echo "==========================================="
    echo " REDIRECT URI VALIDATION"
    echo "==========================================="
    
    if [[ -n "$web_redirect_uris" ]]; then
        log_success "Redirect URIs are configured"
        while IFS= read -r uri; do
            [[ -n "$uri" ]] && log_info "  - $uri"
        done <<< "$(echo "$web_redirect_uris" | tr ',' '\n')"
    else
        log_warn "No redirect URIs configured"
        log_info "This may be intentional for service-to-service authentication"
    fi
    
    echo ""
    log_success "Validation complete!"
}

# Main execution
main() {
    # Check arguments
    if [[ $# -eq 0 ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        usage
    fi
    
    local app_id="$1"
    
    # Basic validation of app ID format (GUID)
    if [[ ! "$app_id" =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]]; then
        log_error "Invalid app ID format. Expected GUID format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
        exit 1
    fi
    
    validate_app_registration "$app_id"
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
