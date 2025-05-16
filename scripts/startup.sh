#!/bin/bash

echo "========== Enable kubectl for current user without sudo =========="
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
mkdir -p ~/.kube
sudo ln -sf /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown -h $(id -u):$(id -g) ~/.kube/config

echo "==>> Completed !"