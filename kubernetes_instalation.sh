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
   
   sudo dnf update -y
   sudo swapoff -a
   (crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | crontab - || true
   sudo dnf update -y
   OS="Fedora_38"
   VERSION="1.28"
   cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

   sudo modprobe overlay
   sudo modprobe br_netfilter
   cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

   sudo sysctl --system


   VERSION=1.6.2
   ARCH=amd64
   curl -LO https://github.com/containerd/containerd/releases/download/v$VERSION/containerd-$VERSION-linux-$ARCH.tar.gz
   curl -LO https://github.com/containerd/containerd/releases/download/v$VERSION/containerd-$VERSION-linux-$ARCH.tar.gz.sha256sum
   sha256sum -c containerd-$VERSION-linux-$ARCH.tar.gz.sha256sum
   sudo tar Cxzvf /usr/local containerd-$VERSION-linux-$ARCH.tar.gz
   sudo mkdir -p /etc/systemd/system/
   sudo curl -L -o /etc/systemd/system/containerd.service https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
   sudo systemctl daemon-reload
   sudo systemctl enable --now containerd
   sudo install -m 755 runc.$ARCH /usr/local/sbin/runc
   curl -LO https://github.com/opencontainers/runc/releases/download/v$VERSION/runc.$ARCH.sha256sum
   
   sudo install -m 755 runc.$ARCH /usr/local/sbin/runc
   ARCH=amd64
   VERSION=1.1.9
   curl -LO https://github.com/opencontainers/runc/releases/download/v$VERSION/runc.$ARCH
   curl -LO https://github.com/opencontainers/runc/releases/download/v$VERSION/runc.$ARCH.sha256sum
   sha256sum -c runc.$ARCH.sha256sum
   runc --version

   ARCH=amd64
   VERSION=v1.1.1
   OS=linux
   curl -LO https://github.com/containernetworking/plugins/releases/download/$VERSION/cni-plugins-$OS-$ARCH-$VERSION.tgz
   sudo mkdir -p /opt/cni/bin
   sudo tar -C /opt/cni/bin -xzvf cni-plugins-$OS-$ARCH-$VERSION.tgz
 

   sudo mkdir -p /etc/containerd
   sudo containerd config default | sudo tee /etc/containerd/config.toml
   sudo systemctl restart containerd
   sudo cat /etc/containerd/config.toml
   sudo vi /etc/containerd/config.toml

[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
  ...
  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
    SystemdCgroup = true     <----------------------- set to True

[plugins."io.containerd.grpc.v1.cri"]
  sandbox_image = "registry.k8s.io/pause:3.2"     <----------------------- set to this

   sudo systemctl restart containerd
  
   sudo setenforce 0
   sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

   cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

   sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
   sudo systemctl enable --now kubelet
   sudo kubeadm init --pod-network-cidr=192.168.0.0/16


-------------------------------------------------------------------------------------------

POST INIT CONFIGS
   
   Add config for kubectl:

   mkdir -p $HOME/.kube
   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
   sudo chown $(id -u):$(id -g) $HOME/.kube/config
   sudo cat $HOME/.kube/config

   export KUBECONFIG=$HOME/.kube/config

   apply network plugin on master:

  kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml     


   join worker node to cluster:

  kubeadm join 13.48.237.22:6443 --token ds9nwo.4265n0z6j17qrtge \
        --discovery-token-ca-cert-hash sha256:93ee9f7fc3032bc461f8e78ddf654b38ffb08a2c7d2bcac7f2da2719ae1daf31


   


---------------------------------------------------------------------------------

jenkins authentication configuration


kubectl create serviceaccount jenkins -n default
kubectl create clusterrolebinding jenkins --clusterrole=cluster-admin --serviceaccount=default:jenkins
TOKEN=$(kubectl create token jenkins -n default --duration=24h)
kubectl create secret generic jenkins-secret --namespace default --from-literal=token=$TOKEN --from-file=ca.crt=/etc/kubernetes/pki/ca.crt
kubectl patch serviceaccount jenkins -n default -p '{"secrets": [{"name": "jenkins-secret"}]}'
cat <<EOF > /tmp/kubeconfig-jenkins.yaml
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: $(kubectl get secret jenkins-secret -n default -o jsonpath="{.data['ca\.crt']}")
    server: $(kubectl config view --minify -o jsonpath="{.clusters[0].cluster.server}")
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    namespace: default
    user: jenkins
  name: jenkins
current-context: jenkins
users:
- name: jenkins
  user:
    token: $TOKEN
EOF

-----------------------------------------------------

config prometheus for metrics

kubectl edit configmap prometheus-prometheus-oper-prometheus -n monitoring
