#!/bin/bash

echo "uninstall helm release -------------------------->"
helm uninstall emqx --namespace emqx
helm uninstall grafana --namespace grafana
helm uninstall loki --namespace lokistack
helm uninstall prometheus --namespace prometheus
helm uninstall traefik --namespace kube-system
helm uninstall traefik-crd --namespace kube-system

echo "completed ---------------------------------------<"