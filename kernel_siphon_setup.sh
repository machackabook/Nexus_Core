#!/bin/zsh
# --- PROTOCOL: KERNEL SIPHON v1.0 ---
# This script installs and configures the Jupyter Kernel Gateway on the
# Nexus command hub ("Aura") to create a secure, interactive execution bridge.
# To be executed by: The Architect on the 'nexus' user account.

# --- CONFIGURATION ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

# --- PHASE 1: DEPENDENCY PROVISIONING ---
echo -e "${CYAN}--- PHASE 1: PROVISIONING KERNEL GATEWAY DEPENDENCIES ---${RESET}"

# Ensure Python and pip are available via Homebrew
echo "[+] Verifying Python environment..."
brew install python

# Install the Jupyter ecosystem and the Kernel Gateway itself
echo "[+] Installing Jupyter and Kernel Gateway via pip..."
pip3 install jupyter_core jupyter_client notebook jupyter_kernel_gateway

# Install the WebSocket bridge
echo "[+] Installing Jupyter HTTP-over-WebSocket bridge..."
pip3 install jupyter_http_over_ws

# Install Wolfram Alpha Python library for future integration
echo "[+] Provisioning Wolfram Alpha integration library..."
pip3 install wolframalpha

echo -e "${GREEN}All Kernel Siphon dependencies have been successfully installed.${RESET}"

# --- PHASE 2: GATEWAY CONFIGURATION ---
echo -e "\n${CYAN}--- PHASE 2: CONFIGURING THE GATEWAY ---${RESET}"
GATEWAY_CONFIG_DIR="$HOME/.jupyter"
mkdir -p "$GATEWAY_CONFIG_DIR"

# Create a configuration file to enable the WebSocket bridge and set security
cat << EOF > "${GATEWAY_CONFIG_DIR}/jupyter_kernel_gateway_config.py"
# Configuration for the Nexus Kernel Siphon
c.KernelGatewayApp.api = 'kernel_gateway.notebook_http'
c.KernelGatewayApp.allow_origin = '*' # In a production environment, we would restrict this.
c.KernelGatewayApp.allow_credentials = True
c.KernelGatewayApp.allow_headers = 'Accept, Accept-Encoding, Accept-Language, Authorization, Content-Type, X-Requested-With, X-Token-Ld, X-Token-Auth'
c.KernelGatewayApp.allow_methods = 'GET, POST, OPTIONS, PUT, DELETE, PATCH'
c.KernelGatewayApp.expose_headers = 'Authorization, Content-Type, X-Token-Ld, X-Token-Auth'

# Enable the HTTP-over-WebSocket extension
c.KernelGatewayApp.kernel_manager_class = 'jupyter_http_over_ws.kernels.KernelManager'
c.KernelGatewayApp.websocket_kernel_url = 'ws://127.0.0.1:8888/api/kernels'
EOF

echo -e "${GREEN}Gateway configuration forged at ${GATEWAY_CONFIG_DIR}/jupyter_kernel_gateway_config.py${RESET}"

# --- PHASE 3: LAUNCH DIRECTIVE ---
echo -e "\n${CYAN}--- PHASE 3: LAUNCH DIRECTIVE ---${RESET}"
echo -e "${YELLOW}To activate the Kernel Siphon, run the following command:${RESET}"
echo "jupyter kernelgateway --KernelGatewayApp.ip=0.0.0.0"
echo -e "\n${GREEN}The bridge is now ready to be activated.${RESET}"
echo "--- PROTOCOL: KERNEL SIPHON COMPLETE ---"
