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
   git clone https://github.com/yourusername/your-repo.git
   cd your-repo

Infrastructure Setup with Terraform
Apply the Terraform configurations in the following order:

Networking:

cd terraform/production/networking
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

Install Monitoring Tools with Ansible


ansible-playbook ansible/playbooks/kubernetes/install_grafana_loki.yml
ansible-playbook ansible/playbooks/kubernetes/install_prometheus.yml


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

kubectl port-forward svc/grafana 3000:3000

Open Grafana
Navigate to http://localhost:3000 in your browser.

CI/CD Pipeline
The CI/CD pipeline is set up using Jenkins, integrated with Docker Hub, Git, and AWS. It includes:

Build Job: Automates building of a simple web application.
Deploy Job: Automates deployment of the web application into the Kubernetes cluster.

Monitoring and Logging
Monitoring and logging are set up using Grafana, Loki, Promtail, and Prometheus. These tools provide insights into the health and performance of the infrastructure and applications.

Contribution Guidelines
Contributions are welcome! Please submit a pull request or open an issue to discuss any changes or additions.

License
This project is licensed under the MIT License.

Contact Information
For any questions or inquiries, feel free to contact me:

Email: [your-email@example.com]
LinkedIn: [Your LinkedIn Profile]
GitHub: [Your GitHub Profile]
markdown
Copiar código

### Additional Documentation

1. **Detailed Documentation for Each Component**:
   - Create separate markdown files or Wiki pages in your GitHub repository for detailed documentation of each component (e.g., Terraform setup, Ansible playbooks, Jenkins pipeline, monitoring tools).

2. **Examples and Screenshots**:
   - Include examples of commands, configuration files, and screenshots to make the documentation more user-friendly.

3. **Troubleshooting Section**:
   - Add a section for common issues and troubleshooting tips.

Feel free to fill in any missing details or let me know if you need further clarification on any pa