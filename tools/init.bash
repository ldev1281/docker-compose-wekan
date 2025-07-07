#!/bin/bash

# -------------------------------------
# Wekan setup script with SMTP URL encoding
# -------------------------------------

# Encode a string for safe URL usage
urlencode() {
    python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" "$1"
}

# Get the absolute path of script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../.env"
VOL_DIR="${SCRIPT_DIR}/../vol/"

WEKAN_MONGO_VERSION=7

# Load existing configuration from .env file
load_existing_env() {
    set -o allexport
    source "$ENV_FILE"
    set +o allexport
}

# Prompt user to confirm or update configuration
prompt_for_configuration() {
    echo "Please enter configuration values (press Enter to keep current/default value):"
    echo ""

    echo "MongoDB settings:"
    read -p "WEKAN_MONGO_VERSION [${WEKAN_MONGO_VERSION:-7}]: " input
    WEKAN_MONGO_VERSION=${input:-${WEKAN_MONGO_VERSION:-7}}

    echo ""
    echo "Wekan settings:"
    read -p "WEKAN_VERSION [${WEKAN_VERSION:-v7.92}]: " input
    WEKAN_VERSION=${input:-${WEKAN_VERSION:-v7.92}}

    read -p "WEKAN_APP_HOSTNAME [${WEKAN_APP_HOSTNAME:-wekan.example.com}]: " input
    WEKAN_APP_HOSTNAME=${input:-${WEKAN_APP_HOSTNAME:-wekan.example.com}}

    read -p "WEKAN_SMTP_FROM [${WEKAN_SMTP_FROM:-wekan@sandbox123.mailgun.org}]: " input
    WEKAN_SMTP_FROM=${input:-${WEKAN_SMTP_FROM:-wekan@sandbox123.mailgun.org}}

    read -p "WEKAN_SMTP_USER [${WEKAN_SMTP_USER:-postmaster@sandbox123.mailgun.org}]: " input
    WEKAN_SMTP_USER=${input:-${WEKAN_SMTP_USER:-postmaster@sandbox123.mailgun.org}}
    ENCODED_SMTP_USER=$(urlencode "$WEKAN_SMTP_USER")

    read -p "WEKAN_SMTP_PASS [${WEKAN_SMTP_PASS:-password}]: " input
    WEKAN_SMTP_PASS=${input:-${WEKAN_SMTP_PASS:-password}}
    ENCODED_SMTP_PASS=$(urlencode "$WEKAN_SMTP_PASS")

    read -p "WEKAN_SOCAT_SMTP_PORT [${WEKAN_SOCAT_SMTP_PORT:-587}]: " input
    WEKAN_SOCAT_SMTP_PORT=${input:-${WEKAN_SOCAT_SMTP_PORT:-587}}

    read -p "WEKAN_SOCAT_SMTP_HOST [${WEKAN_SOCAT_SMTP_HOST:-smtp.mailgun.org}]: " input
    WEKAN_SOCAT_SMTP_HOST=${input:-${WEKAN_SOCAT_SMTP_HOST:-smtp.mailgun.org}}

    read -p "WEKAN_SOCAT_SMTP_SOCKS5H_HOST [${WEKAN_SOCAT_SMTP_SOCKS5H_HOST:-}]: " input
    WEKAN_SOCAT_SMTP_SOCKS5H_HOST=${input:-${WEKAN_SOCAT_SMTP_SOCKS5H_HOST:-}}

    read -p "WEKAN_SOCAT_SMTP_SOCKS5H_PORT [${WEKAN_SOCAT_SMTP_SOCKS5H_PORT:-}]: " input
    WEKAN_SOCAT_SMTP_SOCKS5H_PORT=${input:-${WEKAN_SOCAT_SMTP_SOCKS5H_PORT:-}}

    read -p "WEKAN_SOCAT_SMTP_SOCKS5H_USER [${WEKAN_SOCAT_SMTP_SOCKS5H_USER:-}]: " input
    WEKAN_SOCAT_SMTP_SOCKS5H_USER=${input:-${WEKAN_SOCAT_SMTP_SOCKS5H_USER:-}}

    read -p "WEKAN_SOCAT_SMTP_SOCKS5H_PASSWORD [${WEKAN_SOCAT_SMTP_SOCKS5H_PASSWORD:-}]: " input
    WEKAN_SOCAT_SMTP_SOCKS5H_PASSWORD=${input:-${WEKAN_SOCAT_SMTP_SOCKS5H_PASSWORD:-}}

    read -p "WEKAN_KEYCLOAK_OAUTH [${WEKAN_KEYCLOAK_OAUTH:-yes}]: " input
    WEKAN_KEYCLOAK_OAUTH=${input:-${WEKAN_KEYCLOAK_OAUTH:-yes}}

    if [ "$WEKAN_KEYCLOAK_OAUTH" = "yes" ]; then
        read -p "WEKAN_KEYCLOAK_REALM [${WEKAN_KEYCLOAK_REALM:-master}]: " input
        WEKAN_KEYCLOAK_REALM=${input:-${WEKAN_KEYCLOAK_REALM:-master}}

        read -p "WEKAN_KEYCLOAK_CLIENT_ID [${WEKAN_KEYCLOAK_CLIENT_ID:-wekan}]: " input
        WEKAN_KEYCLOAK_CLIENT_ID=${input:-${WEKAN_KEYCLOAK_CLIENT_ID:-wekan}}

        read -p "WEKAN_KEYCLOAK_SECRET [${WEKAN_KEYCLOAK_SECRET:-}]: " input
        WEKAN_KEYCLOAK_SECRET=${input:-${WEKAN_KEYCLOAK_SECRET:-}}

        read -p "WEKAN_KEYCLOAK_SERVER_URL [${WEKAN_KEYCLOAK_SERVER_URL:-https://auth.example.com}]: " input
        WEKAN_KEYCLOAK_SERVER_URL=${input:-${WEKAN_KEYCLOAK_SERVER_URL:-https://auth.example.com}}
    else
        WEKAN_KEYCLOAK_OAUTH=""
    fi
}

# Display configuration and ask user to confirm
confirm_and_save_configuration() {
    CONFIG_LINES=(
        "# MongoDB"
        "WEKAN_MONGO_VERSION=${WEKAN_MONGO_VERSION}"
        ""
        "# Wekan"
        "WEKAN_VERSION=${WEKAN_VERSION}"
        "WEKAN_APP_HOSTNAME=${WEKAN_APP_HOSTNAME}"
        "WEKAN_SMTP_FROM=${WEKAN_SMTP_FROM}"
        "WEKAN_SMTP_USER=${WEKAN_SMTP_USER}"
        "WEKAN_SMTP_PASS=${WEKAN_SMTP_PASS}"
        "WEKAN_MAIL_URL=smtp://${ENCODED_SMTP_USER}:${ENCODED_SMTP_PASS}@wekan.mailgun.org:${WEKAN_SOCAT_SMTP_PORT}/"
        ""
        "# SMTP socat proxy settings"
        "WEKAN_SOCAT_SMTP_PORT=${WEKAN_SOCAT_SMTP_PORT}"
        "WEKAN_SOCAT_SMTP_HOST=${WEKAN_SOCAT_SMTP_HOST}"
        "WEKAN_SOCAT_SMTP_SOCKS5H_HOST=${WEKAN_SOCAT_SMTP_SOCKS5H_HOST}"
        "WEKAN_SOCAT_SMTP_SOCKS5H_PORT=${WEKAN_SOCAT_SMTP_SOCKS5H_PORT}"
        "WEKAN_SOCAT_SMTP_SOCKS5H_USER=${WEKAN_SOCAT_SMTP_SOCKS5H_USER}"
        "WEKAN_SOCAT_SMTP_SOCKS5H_PASSWORD=${WEKAN_SOCAT_SMTP_SOCKS5H_PASSWORD}"
        ""
        "# Wekan Keycloak OAuth settings"
        "# Set WEKAN_KEYCLOAK_OAUTH empty or comment it out to disables"
        "WEKAN_KEYCLOAK_OAUTH=${WEKAN_KEYCLOAK_OAUTH}"
        "WEKAN_KEYCLOAK_REALM=${WEKAN_KEYCLOAK_REALM:-}"
        "WEKAN_KEYCLOAK_CLIENT_ID=${WEKAN_KEYCLOAK_CLIENT_ID:-}"
        "WEKAN_KEYCLOAK_SECRET=${WEKAN_KEYCLOAK_SECRET:-}"
        "WEKAN_KEYCLOAK_SERVER_URL=${WEKAN_KEYCLOAK_SERVER_URL:-}"
    )

    echo ""
    echo "The following environment configuration will be saved:"
    echo "-----------------------------------------------------"
    for line in "${CONFIG_LINES[@]}"; do
        echo "$line"
    done
    echo "-----------------------------------------------------"
    echo ""

    read -p "Proceed with this configuration? (y/n): " CONFIRM
    echo ""
    if [[ "$CONFIRM" != "y" ]]; then
        echo "Configuration aborted by user."
        echo ""
        exit 1
    fi

    printf "%s\n" "${CONFIG_LINES[@]}" >"$ENV_FILE"
    echo ".env file saved to $ENV_FILE"
    echo ""
}

# Set up containers and initialize
setup_containers() {
    echo "Stopping all containers and removing volumes..."
    docker compose down -v || true

    echo "Clearing volume data..."
    [ -d "${VOL_DIR}" ] && rm -rf "${VOL_DIR}"/*
    mkdir -p "${VOL_DIR}wekan-app/data" && chown 999:999 "${VOL_DIR}wekan-app/data"

    echo "Starting containers..."
    docker compose up -d

    echo "Waiting 60 seconds for services to initialize..."
    sleep 60

    echo "Done! Wekan should be available at: $WEKAN_APP_HOSTNAME"
    echo ""
}

# -----------------------------------
# Main logic
# -----------------------------------

if [ -f "$ENV_FILE" ]; then
    echo ".env file found. Loading existing configuration."
    load_existing_env
else
    echo ".env file not found. Starting interactive configuration."
fi

prompt_for_configuration
confirm_and_save_configuration
setup_containers
