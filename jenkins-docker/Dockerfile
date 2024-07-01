FROM jenkins/jenkins:lts

# Install Docker CLI
USER root
RUN apt-get update && \
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg2 python3-venv && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" && \
    apt-get update && \
    apt-get install -y docker-ce-cli && \
    groupadd docker && \
    usermod -aG docker jenkins

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl

# Create a virtual environment and install boto3
RUN python3 -m venv /opt/venv && \
    /opt/venv/bin/pip install boto3

# Make sure the virtual environment is available in the Jenkins user environment
ENV PATH="/opt/venv/bin:$PATH"

# Install Ansible
RUN apt-get update && \
    apt-get install -y ansible

# Switch back to Jenkins user
USER jenkins