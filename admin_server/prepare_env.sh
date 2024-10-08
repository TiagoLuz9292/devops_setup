#create private key, and make chmod 600
sudo chmod 600 /home/ec2-user/.ssh/my-key-pair
eval "$(ssh-agent -s)"
ssh-add /home/ec2-user/.ssh/my-key-pair

sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install terraform
sudo yum install -y nc

sudo yum update -y
sudo yum install ansible -y

sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER


curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

#copy ed25519 amd ed25519.pub key into new server 



echo 'eval "$(ssh-agent -s)"' >> ~/.bashrc
echo 'ssh-add /home/ec2-user/.ssh/my-key-pair' >> ~/.bashrc
source ~/.bashrc

sudo yum install git

cd /home/ec2-user
git clone git@github.com:TiagoLuz9292/devops_setup.git

cd /home/ec2-user/devops_setup/admin_server

chmod +x set_env_vars.sh
chmod +x prepare_env.sh 

./set_env_vars.sh