#!/bin/zsh
# Activation script for Nexus Kernel Siphon
source "/Users/nexus/.nexus_kernel_siphon/bin/activate"
echo -e "\033[0;32mKernel Siphon virtual environment activated.\033[0m"
echo -e "\033[1;33mTo start the gateway, run:\033[0m"
echo "jupyter kernelgateway --KernelGatewayApp.ip=0.0.0.0"
