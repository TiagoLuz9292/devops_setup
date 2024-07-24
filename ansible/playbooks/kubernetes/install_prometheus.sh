helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack --namespace=grafana-loki
kubectl apply -f /home/ec2-user/devops_setup/kubernetes/prometheus/pvs.yaml
kubectl apply -f /home/ec2-user/devops_setup/kubernetes/prometheus/pvcs.yaml --validate=false