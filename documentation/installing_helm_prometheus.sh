curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm install prometheus prometheus-community/kube-prometheus-stack

kubectl patch svc prometheus-kube-prometheus-prometheus -n default -p '{"spec": {"type": "NodePort"}}'


helm install grafana grafana/grafana

kubectl patch svc grafana -p '{"spec": {"type": "NodePort"}}'


Create a file named pvs.yaml (/root/project/devops/kubernetes/prometheus/pvs.yaml):

apiVersion: v1
kind: PersistentVolume
metadata:
  name: prometheus-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  hostPath:
    path: /mnt/data/prometheus
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: alertmanager-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  hostPath:
    path: /mnt/data/alertmanager

kubectl apply -f pvs.yaml



Create a file named pvcs.yaml (/root/project/devops/kubernetes/prometheus/pvcs.yaml):

apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: prometheus-server
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: manual
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: storage-prometheus-alertmanager-0
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: manual


kubectl apply -f pvcs.yaml


kubectl get svc -n default


NAME                        TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                         AGE
prometheus-kube-prometheus-prometheus  NodePort    10.103.230.142   <none>        9090:32181/TCP                 7m47s
grafana                     NodePort    10.97.235.211    <none>        80:32542/TCP                    7m23s

In this example:

Prometheus NodePort is 32181
Grafana NodePort is 32542


ON LOCAL MACHINE:

Check SSH Key Permissions:
Ensure your SSH key has the correct permissions:

chmod 700 ~/.ssh
chmod 600 ~/.ssh/my-key-pair


ssh -i ~/.ssh/my-key-pair -L 9090:localhost:31476 -L 3000:localhost:32181 ec2-user@13.49.161.125

if ports are being used, increment 1 to the port value on local

http://localhost:3001

http://localhost:9091


OPEN PORT 9100 INBOUND RULE for Node Expoerter (for hardware metrics)

prometheus url for grafana data source:

http://<prometheus-service-name>.<namespace>.svc.cluster.local:<prometheus-service-port>