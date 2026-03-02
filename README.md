## Usage
run the following command to install kubeadm:

```ssh
curl -sSL https://raw.githubusercontent.com/BGMSound/kubeadm-installer/main/kubeadm-install.sh | sudo bash
```

to initialize the control plane:

```ssh
sudo kubeadm init \
    --control-plane-endpoint=<YOUR_CONTROL_PLANE_ENDPOINT> \
    --apiserver-advertise-address=<YOUR_APISERVER_ADVERTISE_ADDRESS> \
    --pod-network-cidr=10.244.0.0/16 \
    --service-cidr=10.96.0.0/12 \
    --upload-certs
```