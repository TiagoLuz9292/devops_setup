sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install terraform

ssh-keygen -t ed25519 -C "tiagoluz92@gmail.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

sudo yum install git
git clone git@github.com:TiagoLuz9292/devops_setup.git

cd devops_setup/

chmod +x set_env_vars.sh
chmod +x prepare_env.sh 
chmod +x install_kubectl.sh 

./set_env_vars.sh