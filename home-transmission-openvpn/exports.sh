#!/bin/bash

# =============================================================================
# exports.sh — Share connection details with other Umbrel apps
# =============================================================================
# These environment variables are available to all other Umbrel apps.
# Radarr and Sonarr can use these to auto-configure this download client.
# =============================================================================

# Transmission RPC connection details
export APP_TRANSMISSION_OPENVPN_RPC_HOST="home-transmission-openvpn_transmission-openvpn_1"
export APP_TRANSMISSION_OPENVPN_RPC_PORT="9091"
export APP_TRANSMISSION_OPENVPN_RPC_URL="/transmission/"

# Download directory (as seen inside Radarr/Sonarr containers)
export APP_TRANSMISSION_OPENVPN_DOWNLOAD_DIR="/downloads/complete"
