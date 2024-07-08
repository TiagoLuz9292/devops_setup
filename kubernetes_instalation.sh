#!/bin/bash
#
# Common setup for all servers (Control Plane and Nodes)

set -euxo pipefail

# Kuernetes Variable Declaration

KUBERNETES_VERSION="1.30"

# disable swap
sudo swapoff -a

# keeps the swaf off during reboot
(crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | crontab - || true
sudo apt-get update -y


# Install CRI-O Runtime

OS="Fedora_38"

VERSION="1.28"

# Create the .conf file to load the modules at bootup
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

sudo tee /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo <<EOF
[devel_kubic_libcontainers_stable]
name=devel:kubic:libcontainers:stable
baseurl=https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/Fedora_38/
gpgcheck=1
gpgkey=https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/Release.key
enabled=1
EOF

sudo tee /etc/yum.repos.d/devel:kubic:libcontainers:stable:cri-o:\$VERSION.repo <<EOF
[devel_kubic_libcontainers_stable_cri-o_\$VERSION]
name=devel:kubic:libcontainers:stable:cri-o:\$VERSION
baseurl=https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/1.28/Fedora_38/
gpgcheck=1
gpgkey=https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/1.28/Fedora_38/Release.key
enabled=1
EOF

curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/Release.key | sudo rpm --import -
curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/1.28/Fedora_38/Release.key | sudo rpm --import -

sudo apt-get update
sudo apt-get install cri-o cri-o-runc -y

sudo systemctl daemon-reload
sudo systemctl enable crio --now

echo "CRI runtime installed susccessfully"

# Install kubelet, kubectl and Kubeadm

sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

sudo apt-get update -y
sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl enable --now kubelet
sudo apt-get update -y



local_ip="$(ip --json addr show eth0 | jq -r '.[0].addr_info[] | select(.family == "inet") | .local')"
cat > /etc/default/kubelet << EOF
KUBELET_EXTRA_ARGS=--node-ip=$local_ip
EOF



----------------------------------------------------------------------------------------------



[ec2-user@ip-10-0-1-122 ~]$ history
   
    4  sudo dnf update -y
    9  sudo swapoff -a
   10  (crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | crontab - || true
   11  sudo dnf update -y
   12  OS="Fedora_38"
   13  VERSION="1.28"
   14  cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

   15  sudo modprobe overlay
   16  sudo modprobe br_netfilter
   17  cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

   18  sudo sysctl --system


   32  VERSION=1.6.2
   33  ARCH=amd64
   34  curl -LO https://github.com/containerd/containerd/releases/download/v$VERSION/containerd-$VERSION-linux-$ARCH.tar.gz
   35  curl -LO https://github.com/containerd/containerd/releases/download/v$VERSION/containerd-$VERSION-linux-$ARCH.tar.gz.sha256sum
   36  sha256sum -c containerd-$VERSION-linux-$ARCH.tar.gz.sha256sum
   37  sudo tar Cxzvf /usr/local containerd-$VERSION-linux-$ARCH.tar.gz
   39  sudo mkdir -p /etc/systemd/system/
   40  sudo curl -L -o /etc/systemd/system/containerd.service https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
   41  sudo systemctl daemon-reload
   42  sudo systemctl enable --now containerd
   43  sudo install -m 755 runc.$ARCH /usr/local/sbin/runc
   44  curl -LO https://github.com/opencontainers/runc/releases/download/v$VERSION/runc.$ARCH.sha256sum
   46
   51  sudo install -m 755 runc.$ARCH /usr/local/sbin/runc
   52  ARCH=amd64
   53  VERSION=1.1.9
   54  curl -LO https://github.com/opencontainers/runc/releases/download/v$VERSION/runc.$ARCH
   55  curl -LO https://github.com/opencontainers/runc/releases/download/v$VERSION/runc.$ARCH.sha256sum
   56  sha256sum -c runc.$ARCH.sha256sum
   58  runc --version

   59  ARCH=amd64
   60  VERSION=v1.1.1
   61  OS=linux
   62  curl -LO https://github.com/containernetworking/plugins/releases/download/$VERSION/cni-plugins-$OS-$ARCH-$VERSION.tgz
   63  sudo mkdir -p /opt/cni/bin
   64  sudo tar -C /opt/cni/bin -xzvf cni-plugins-$OS-$ARCH-$VERSION.tgz
 

   76  sudo mkdir -p /etc/containerd
   77  sudo containerd config default | sudo tee /etc/containerd/config.toml
   78  sudo systemctl restart containerd
   79  sudo cat /etc/containerd/config.toml
   80  sudo vi /etc/containerd/config.toml

[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
  ...
  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
    SystemdCgroup = true     <----------------------- set to True

[plugins."io.containerd.grpc.v1.cri"]
  sandbox_image = "registry.k8s.io/pause:3.2"     <----------------------- set to this

   81  sudo systemctl restart containerd
  
   84  sudo setenforce 0
   85  sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

   86  cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

   87  sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
   88  sudo systemctl enable --now kubelet
   89  sudo kubeadm init --pod-network-cidr=192.168.0.0/16
   
   90  mkdir -p $HOME/.kube
   91  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
   92  sudo chown $(id -u):$(id -g) $HOME/.kube/config
   93  sudo cat $HOME/.kube/config
   94  history