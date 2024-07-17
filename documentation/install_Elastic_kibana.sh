helm repo add elastic https://helm.elastic.co
helm repo update

curl -O https://raw.githubusercontent.com/elastic/helm-charts/master/elasticsearch/examples/minikube/values.yaml
helm install elasticsearch elastic/elasticsearch -f ./values.yaml

Step-by-Step Guide to Fix Persistent Volume Claims for Elasticsearch
Your issue is that the PersistentVolumeClaims (PVCs) for Elasticsearch are pending due to no available PersistentVolumes (PVs). Here’s how you can fix this:

Step 1: Verify the PVCs and PVs
You've already checked the PVCs and PVs, and the Elasticsearch PVCs are in a pending state because there are no available PVs with the correct storage class.

Step 2: Create Persistent Volumes for Elasticsearch
Create a YAML file for the PersistentVolumes
Create a file named elasticsearch-pv.yaml with the following content:
yaml
Copiar código
apiVersion: v1
kind: PersistentVolume
metadata:
  name: elasticsearch-pv-0
spec:
  capacity:
    storage: 20Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: standard
  hostPath:
    path: /mnt/data/elasticsearch-0
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: elasticsearch-pv-1
spec:
  capacity:
    storage: 20Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: standard
  hostPath:
    path: /mnt/data/elasticsearch-1
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: elasticsearch-pv-2
spec:
  capacity:
    storage: 20Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: standard
  hostPath:
    path: /mnt/data/elasticsearch-2
Apply the PV configuration:
bash
Copiar código
kubectl apply -f elasticsearch-pv.yaml
Step 3: Check the Status of the PVCs and PVs
After creating the PVs, check the status of the PVCs to ensure they are bound.

bash
Copiar código
kubectl get pvc --namespace=default
kubectl get pv



Create a self-signed certificate for Elasticsearch:

openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout elasticsearch.key -out elasticsearch.crt -subj "/CN=elasticsearch"

Create a Kubernetes secret with the certificate:

kubectl create secret generic elasticsearch-master-certs --from-file=elasticsearch.key --from-file=elasticsearch.crt -n kibana

Create another secret for Elasticsearch credentials (username and password):

kubectl create secret generic elasticsearch-master-credentials --from-literal=username=elastic --from-literal=password=changeme -n kibana



------------------------------------

possible errors:

kibana pods not starting:

Warning  FailedMount  9s (x10 over 4m19s)  kubelet            MountVolume.SetUp failed for volume "elasticsearch-certs" : secret "elasticsearch-master-certs" not found
solution: configure secret for elasticsearch before installing kibana


Delete the ConfigMap:

sh
Copiar código
kubectl delete configmap kibana-kibana-helm-scripts -n kibana
Uninstall Kibana:

sh
Copiar código
helm uninstall kibana -n kibana
Delete All Remaining Resources in Kibana Namespace:

sh
Copiar código
kubectl delete all --all -n kibana
kubectl delete secret --all -n kibana