helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm search repo loki
helm upgrade --install --values /home/ec2-user/devops_setup/kubernetes/loki/loki.yaml loki grafana/loki-stack -n grafana-loki --create-namespace