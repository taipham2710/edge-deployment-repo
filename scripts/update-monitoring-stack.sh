#!/bin/bash
# Script cập nhật toàn bộ stack monitoring

echo "==== Đang cập nhật Prometheus ===="
helm upgrade prometheus prometheus-community/prometheus \
  --namespace prometheus \
  -f ../helm_values/values.yaml

echo "==== Đang cập nhật Loki ===="
helm upgrade loki grafana/loki-stack \
  --namespace lokistack \
  -f ../helm_values/values.yaml

echo "==== Đang cập nhật EMQX ===="
helm upgrade emqx emqx/emqx \
  --namespace emqx \
  -f ../helm_values/values.yaml

echo "==== Đang cập nhật Grafana ===="
helm upgrade grafana grafana/grafana \
  --namespace grafana \
  -f ../helm_values/values.yaml

echo "==== Áp dụng cấu hình Ingress ===="
sudo kubectl apply -f ../kubernetes_manifests/ingress/all-ingress.yaml

echo "==== Kiểm tra trạng thái các pods ===="
sudo kubectl get pods -n prometheus
sudo kubectl get pods -n lokistack
sudo kubectl get pods -n emqx
sudo kubectl get pods -n grafana

echo "==== Cập nhật hoàn tất! ===="