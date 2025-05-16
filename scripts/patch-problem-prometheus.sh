#!/bin/bash

#Error: UPGRADE FAILED: cannot patch "prometheus-server" with kind PersistentVolumeClaim: persistentvolumeclaims "prometheus-server" 
#is forbidden: only dynamically provisioned pvc can be resized and the storageclass that provisions the pvc must support resize && 
#cannot patch "prometheus-alertmanager" with kind StatefulSet: StatefulSet.apps "prometheus-alertmanager" is invalid: spec: Forbidden: 
#updates to statefulset spec for fields other than 'replicas', 'ordinals', 'template', 'updateStrategy', 'persistentVolumeClaimRetentionPolicy' and 'minReadySeconds' are forbidden

echo "--------------Xóa Prometheus và Alertmanager deployments để giải phóng PVC------------------"
sudo kubectl delete deploy -n prometheus prometheus-server
sudo kubectl delete statefulset -n prometheus prometheus-alertmanager

echo "--------------Xóa PVC cũ (mất dữ liệu metrics cũ!)------------------------------------------"
sudo kubectl delete pvc -n prometheus prometheus-server
sudo kubectl delete pvc -n prometheus prometheus-alertmanager-prometheus-alertmanager-0

echo "Upgrade lại Helm chart với values.yaml"
helm upgrade prometheus prometheus-community/prometheus -n prometheus -f ../helm_values/promtheus/values.yaml

echo "-----------patch deployment------------"
sudo kubectl -n prometheus patch deployment prometheus-server --type=strategic -p '{
  "spec": {
    "template": {
      "spec": {
        "containers": [{
          "name": "prometheus-server",
          "livenessProbe": {
            "httpGet": {"path":"/prometheus/-/healthy","port":9090},
            "initialDelaySeconds":30,
            "timeoutSeconds":5,
            "failureThreshold":6
          },
          "readinessProbe": {
            "httpGet": {"path":"/prometheus/-/ready","port":9090},
            "initialDelaySeconds":30,
            "timeoutSeconds":5,
            "failureThreshold":6
          }
        }]
      }
    }
  }
}'