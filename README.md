# Comprehensive AWS Cloud Infrastructure Project

## Description

This project showcases a robust AWS cloud infrastructure with a Kubernetes cluster (master and worker nodes) within a single VPC. It utilizes Terraform for infrastructure as code and Jenkins for CI/CD pipelines, focusing on scalability, monitoring, and continuous integration/continuous deployment (CI/CD) pipelines.

## Table of Contents

1. [Infrastructure Overview](#infrastructure-overview)
2. [Architecture Diagram](#architecture-diagram)
3. [Setup and Installation](#setup-and-installation)
4. [Usage](#usage)
5. [CI/CD Pipeline](#cicd-pipeline)
6. [Monitoring and Logging](#monitoring-and-logging)
7. [Contribution Guidelines](#contribution-guidelines)
8. [License](#license)
9. [Contact Information](#contact-information)

## Infrastructure Overview

The infrastructure includes:
- **VPC**: A virtual private cloud with subnets for high availability.
- **Subnets**: Two public subnets in different availability zones for an Elastic Load Balancer and one subnet for the admin server.
- **Kubernetes Cluster**: A master node and auto-scaling worker nodes.
- **Auto Scaling Group (ASG)**: Manages Kubernetes worker nodes, triggered by CloudWatch alarms.
- **Security Groups**: Configured for secure access and operations.
- **IAM Roles and Policies**: For managing permissions and access controls.
- **Monitoring and Logging**: Using Grafana, Loki, Promtail, and Prometheus.

## Architecture Diagram

*Include an architecture diagram here illustrating the setup.*

## Setup and Installation

### Prerequisites

- AWS account
- Terraform installed
- Ansible installed
- kubectl installed
- Helm installed
- Docker installed

### Installation Steps

1. **Clone the Repository**
   git clone https://github.com/TiagoLuz9292/devops_setup.git
   cd your-repo

Infrastructure Setup with Terraform
Apply the Terraform configurations in the following order:

Networking:

cd devops_setup/terraform/production/networking
terraform init
terraform apply

Admin:

cd ../admin
terraform init
terraform apply

Kubernetes Cluster:

cd ../k8s_cluster
terraform init
terraform apply

Notifications (CloudWatch):

cd ../notifications
terraform init
terraform apply

Kubernetes Cluster Setup with Ansible

ansible-playbook ansible/playbooks/kubernetes/setup_kubernetes_cluster.yml
ansible-playbook ansible/playbooks/kubernetes/setup_kubectl_auth.yml

Install Grafana + Promtail + Loki (Loki data source comes already setup on Grafana)

/home/ec2-user/devops_setup/ansible/playbooks/kubernetes/install_grafana_loki.sh

Install Prometheus (Prometheus data source needs to be added manually on Grafana with this url: )

/home/ec2-user/devops_setup/ansible/playbooks/kubernetes/install_prometheus.sh


Configure the Admin Server

ansible-playbook ansible/prepare_env.yml
Run Jenkins on Admin Server

docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v /root/aws_credentials:/home/ec2-user/.aws \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /home/ec2-user/devops_setup:/home/ec2-user/devops_setup \
  -v /home/tluz/jenkins_home:/var/jenkins_home \
  -v /root/project:/root/project \
  --user root \
  my-jenkins


Usage

Deploying Applications
Build Application

Jenkins job to build the application:

Go to Jenkins dashboard
Trigger the build job
Deploy Application

Jenkins job to deploy the application:

Go to Jenkins dashboard
Trigger the deploy job
Accessing Grafana Dashboards

Port Forward Grafana

kubectl port-forward pod/loki-grafana-75499f7c6b-99csg -n grafana-loki 9090:3000     #Replace with the name of the grafana pod

Open Grafana
Navigate to http://localhost:9090 in your browser.

CI/CD Pipeline
The CI/CD pipeline is set up using Jenkins, integrated with Docker Hub, Git, and AWS. It includes:

Build Job: Automates building of a simple web application.
Deploy Job: Automates deployment of the web application into the Kubernetes cluster.

Monitoring and Logging

Monitoring and logging are set up using Grafana, Loki, Promtail, and Prometheus. These tools provide insights into the health and performance of the infrastructure and applications.

Contribution Guidelines

Contributions are welcome! Please submit a pull request or open an issue to discuss any changes or additions.



Contact Information
For any questions or inquiries, feel free to contact me:

Email: [tiagoluz92@gmail.com]
LinkedIn: [https://www.linkedin.com/in/tiagoluz92]
GitHub: [https://github.com/TiagoLuz9292]

