helm uninstall prometheus -n monitoring
helm uninstall grafana -n monitoring
kubectl delete namespace monitoring
kubectl delete pvc -n monitoring --all
sudo apt-get remove --purge helm
sudo yum remove helm
rm -rf ~/.helm
kubectl delete clusterrole prometheus-operator
kubectl delete clusterrolebinding prometheus-operator
kubectl delete clusterrolebinding grafana
kubectl delete crd prometheuses.monitoring.coreos.com
kubectl delete crd alertmanagers.monitoring.coreos.com
kubectl delete crd prometheusrules.monitoring.coreos.com
kubectl delete crd servicemonitors.monitoring.coreos.com
kubectl delete crd podmonitors.monitoring.coreos.com
kubectl delete crd thanosrulers.monitoring.coreos.com