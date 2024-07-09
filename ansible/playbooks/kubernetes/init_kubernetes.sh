NODENAME=$(hostname -s)
POD_CIDR="192.168.0.0/16"
MASTER_PRIVATE_IP="13.48.237.22"

sudo kubeadm init --control-plane-endpoint="$MASTER_PUBLIC_IP" --apiserver-cert-extra-sans="$MASTER_PUBLIC_IP" --pod-network-cidr="$POD_CIDR" --node-name "$NODENAME" --ignore-preflight-errors Swap