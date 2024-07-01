# devops_setup

Project and System Configuration Documentation
Overview
This document provides an overview of the setup and configuration of a CI/CD pipeline using Jenkins, Ansible, Terraform, and Docker. The system is designed to build and deploy a web application consisting of a frontend and backend service. The application is deployed to AWS EC2 instances using Docker containers.

Directory Structure
The directory structure for the project is as follows:


devops/
  ├── ansible/
  │   ├── playbooks/
  │   │   ├── deploy-deploy_script.yaml
  │   │   ├── deploy-main.yaml
  │   │   ├── install_docker.yaml
  │   │   ├── prepare_environment.yaml
  │   │   └── test.yaml
  │   ├── roles/common/tasks/
  │   │   ├── deploy-script.yaml
  │   │   ├── docker.yaml
  │   │   └── environment.yaml
  │   ├── ansible.cfg
  │   ├── deploy-deploy_script.sh
  │   ├── install_docker.sh
  │   ├── inventory.ini
  │   ├── prepare_environment.sh
  │   ├── test.txt
  ├── applications/solana-spl-momentum-scanner/
  │   ├── config.json
  │   ├── Jenkinsfile
  ├── terraform/
  │   ├── .terraform/
  │   ├── .terraform.lock.hcl
  │   ├── main.tf
  │   ├── outputs.tf
  │   ├── provider.tf
  │   ├── terraform.tfstate
  │   ├── variables.tf
  ├── .gitattributes
  ├── aws_ec2_inventory.py
  ├── bfg.jar
  ├── deploy.sh
  └── README.md


-Components

1. Jenkins
Jenkins is used as the CI/CD tool running in a Docker container. It has two main jobs:

Build Job: This job pulls the source code from the GitHub repository, builds the Docker images for the frontend and backend services, and pushes them to Docker Hub.
Deploy Job: This job deploys the Docker images from Docker Hub to the target EC2 instances using Ansible.
2. Ansible
Ansible is used for configuration management and deployment. It handles tasks such as:

Setting up the environment on EC2 instances
Installing Docker
Deploying the application
Key Playbooks:
deploy-main.yaml: Main playbook for deploying the application.
install_docker.yaml: Playbook to install Docker on EC2 instances.
prepare_environment.yaml: Playbook to prepare the environment for the application.
deploy-deploy_script.yaml: Playbook to copy and execute the deployment script on EC2 instances.
3. Terraform
Terraform is used for provisioning the infrastructure on AWS. It manages the creation and configuration of EC2 instances.

Key Files:
main.tf: Defines the infrastructure resources.
variables.tf: Contains variable definitions.
outputs.tf: Defines the output values.
provider.tf: Configures the AWS provider.
4. Docker
Docker is used for containerizing the application. The application consists of two Docker images:

Frontend: A simple web app that receives a string input.
Backend: A FastAPI application that processes the input and returns price data about a Solana SPL token.
5. Application Repository
The application repository contains the source code for the frontend and backend services. It also contains the Jenkinsfile used to build and push Docker images.

6. Dynamic Inventory Script
The aws_ec2_inventory.py script dynamically generates an inventory of running EC2 instances, and it can use filters to work with the instance tags. It uses AWS credentials configured on the Jenkins server to access AWS and retrieve instance information.

Deployment Process
-Build and Push Docker Images:

Jenkins pulls the latest source code from GitHub.
Jenkins builds the Docker images for the frontend and backend services.
Jenkins pushes the images to Docker Hub.

-Deploy Docker Images to EC2:

Jenkins triggers the deployment job.
Ansible playbooks are executed to set up the environment on EC2 instances, install Docker, and deploy the application.

The Docker images are pulled from Docker Hub into the EC2 instances;
The deploy.sh script is copied to the EC2 instances and executed to pull the latest Docker images from Docker Hub and run them with the porst configured on Configuration File config.json

Example:

{
  "frontend": {
    "port": 3000
  },
  "backend": {
    "port": 5000
  }
}
Jenkinsfile
The Jenkinsfile in the applications/solana-spl-momentum-scanner/ directory is used to define the deployment pipeline for the application. It will probably be moved into the app source code repo in the future.

Conclusion
This documentation provides a high-level overview of the CI/CD pipeline setup using Jenkins, Ansible, Terraform, and Docker. The system automates the process of building, pushing, and deploying Docker images for a web application to AWS EC2 instances.

For more detailed information, refer to the individual playbooks, scripts, and configuration files mentioned in this document.


--------------------------------------------

Important commands


  docker run -d \
  --name jenkins \
  --group-add $(getent group docker | cut -d: -f3) \
  -p 8080:8080 \
  -p 50000:50000 \
  -v /root/aws_credentials:/root/.aws \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /home/tluz/jenkins_home:/var/jenkins_home \
  -v /root/project:/root/project \
  --user root \
  custom-jenkins


echo 'export ANSIBLE_PRIVATE_KEY_FILE=/root/.ssh/my-key-pair' >> ~/.bashrc