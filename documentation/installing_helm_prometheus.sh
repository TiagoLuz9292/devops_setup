curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm install prometheus prometheus-community/kube-prometheus-stack

kubectl patch svc prometheus-kube-prometheus-prometheus -n logging -p '{"spec": {"type": "NodePort"}}'


helm install grafana grafana/grafana

kubectl patch svc grafana -n logging -p '{"spec": {"type": "NodePort"}}'


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


ssh -i ~/.ssh/my-key-pair -L 9091:localhost:31236 -L 3001:localhost:31586 ec2-user@13.48.205.68

if ports are being used, increment 1 to the port value on local

http://localhost:3001

http://localhost:9091


OPEN PORT 9100 INBOUND RULE for Node Expoerter (for hardware metrics)

get grafana password:

kubectl get secret --namespace logging grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

OR

kubectl get secret --namespace logging loki-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

prometheus url for grafana data source:

http://<prometheus-service-name>.<namespace>.svc.cluster.local:<prometheus-service-port>


tunel for grafana, prom, and loki:

ssh -i ~/.ssh/my-key-pair -L 3001:localhost:31189 ec2-user@16.171.115.10

ssh -i ~/.ssh/my-key-pair -L 9090:localhost:30897 -L 9091:localhost:31127 ec2-user@13.49.68.129
ssh -i ~/.ssh/my-key-pair -L 9091:localhost:31127 ec2-user@<public-ip-of-10-0-2-177>

NEW APPROACH ONLY ONE SSH COMMAND FOR TUNNEL:

ssh -i ~/.ssh/my-key-pair -L 9091:10.0.2.177:31127 -L 3001:10.0.1.26:31189 -L 9090:10.0.2.177:30897 ec2-user@16.16.30.32


/usr/share/grafana $ curl -G -s "http://10.0.2.177:31127/loki/api/v1/query_range" --data-urlencode "query={job=\"prometheus\"}" --data-urlencode "start=1612905600000000000" --data-urlencode "e
nd=1612912800000000000"
{"status":"success","data":{"resultType":"streams","result":[],"stats":{"summary":{"bytesProcessedPerSecond":0,"linesProcessedPerSecond":0,"totalBytesProcessed":0,"totalLinesProcessed":0,"execTime":0.000271083,"queueTime":0.000039171,"subqueries":1,"totalEntriesReturned":0},"querier":{"store":{"totalChunksRef":0,"totalChunksDownloaded":0,"chunksDownloadTime":0,"chunk":{"headChunkBytes":0,"headChunkLines":0,"decompressedBytes":0,"decompressedLines":0,"compressedBytes":0,"totalDuplicates":0}}},"ingester":{"totalReached":0,"totalChunksMatched":0,"totalBatches":0,"totalLinesSent":0,"store":{"totalChunksRef":0,"totalChunksDownloaded":0,"chunksDownloadTime":0,"chunk":{"headChunkBytes":0,"headChunkLines":0,"decompressedBytes":0,"decompressedLines":0,"compressedBytes":0,"totalDuplicates":0}}}}}}
/usr/share/grafana $ kubectl logs -l app.kubernetes.io/name=grafana -n default