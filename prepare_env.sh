sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install terraform
sudo yum install -y nc

sudo yum update -y
sudo yum install ansible -y

#copy ed25519 amd ed25519.pub key into new server 

eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

sudo yum install git
git clone git@github.com:TiagoLuz9292/devops_setup.git

cd devops_setup/

chmod +x set_env_vars.sh
chmod +x prepare_env.sh 
chmod +x install_kubectl.sh 

./set_env_vars.sh