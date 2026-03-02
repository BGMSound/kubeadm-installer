#!/bin/bash

# Color definitions
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Default values
K8S_VERSION="v1.35"

# Status message functions
function info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

function success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

function warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

function error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Help message
function show_help() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --version <version>  Kubernetes version to install (default: $K8S_VERSION)"
    echo "  -h, --help           Show this help message"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --version)
            K8S_VERSION="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

# Stop immediately on error
set -e

info "Starting Kubeadm installation (Version: $K8S_VERSION)..."

info "Updating system and installing base packages (apt-transport-https, ca-certificates, curl)..."
sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl
success "Essential packages installed."

# 2. sysctl configuration (Networking)
info "Configuring system networking (sysctl)..."
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system
success "sysctl configuration complete."

# 3. Kubernetes repository and GPG key setup
info "Setting up Kubernetes APT repository and GPG key ($K8S_VERSION)..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/$K8S_VERSION/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg || true
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$K8S_VERSION/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
success "Repository setup complete."

# 4. kubelet, kubeadm, kubectl installation
info "Installing kubelet, kubeadm, and kubectl..."
sudo apt-get update -y
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
success "Kubernetes binaries installed."

# 5. Containerd installation and configuration
info "Installing and configuring containerd..."
sudo apt update && sudo apt install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sed 's/SystemdCgroup = false/SystemdCgroup = true/' | sudo tee /etc/containerd/config.toml > /dev/null
sudo systemctl restart containerd
success "containerd configured and restarted."

# 6. Disable Swap
info "Disabling Swap..."
sudo swapoff -a
sudo sed -i '/swap/s/^/#/' /etc/fstab
sudo sysctl -p
success "Swap disabled and environment configuration complete."

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  Kubeadm installation is complete!${NC}"
echo -e "${GREEN}========================================${NC}"
info "You can now initialize the cluster using 'sudo kubeadm init'."
