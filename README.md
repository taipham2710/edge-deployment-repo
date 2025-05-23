# Dự Án Triển Khai Hạ Tầng Edge (Edge Infrastructure Deployment)

Dự án này thiết lập một cụm Kubernetes (K3s) trên các máy ảo Edge, cùng với các dịch vụ giám sát (Prometheus, Grafana, Loki) và một MQTT Broker (EMQX) để phục vụ cho các ứng dụng IoT.

## Mục Lục

* [Kiến Trúc Tổng Quan](#kiến-trúc-tổng-quan)
* [Yêu Cầu Hệ Thống](#yêu-cầu-hệ-thống)
* [Công Cụ Cần Thiết](#công-cụ-cần-thiết)
* [Hướng Dẫn Cài Đặt](#hướng-dẫn-cài-đặt)
  * [1. Cài Đặt K3s Cluster](#1-cài-đặt-k3s-cluster)
  * [2. Cài Đặt MQTT Broker (EMQX)](#2-cài-đặt-mqtt-broker-emqx)
  * [3. Cài Đặt Bộ Công Cụ Giám Sát](#3-cài-đặt-bộ-công-cụ-giám-sát)
  * [4. Cấu Hình Ingress](#4-cấu-hình-ingress)
  * [5. Cấu hình Egress](#5-cấu-hình-egress-network-policies)
* [Truy Cập Các Dịch Vụ](#truy-cập-các-dịch-vụ)
* [Cấu Trúc Thư Mục](#cấu-trúc-thư-mục)

---

## Kiến Trúc Tổng Quan (Tùy chọn)

---

## Yêu Cầu Hệ Thống

* Các máy ảo (VMs) cho K3s master và worker nodes (ví dụ: Ubuntu Server 22.04 LTS).
* Kết nối mạng giữa các VMs.
* Quyền `sudo` trên các VMs.

---

## Công Cụ Cần Thiết

Đảm bảo các công cụ sau đã được cài đặt trên máy tính bạn dùng để quản lý cluster:

* **`kubectl`**: Công cụ dòng lệnh của Kubernetes.
  * *Hướng dẫn cài đặt: [Install kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)*
* **`helm`**: Trình quản lý package cho Kubernetes.
  * *Hướng dẫn cài đặt: [Installing Helm](https://helm.sh/docs/intro/install/)*
* **(Tùy chọn) `k3sup`**: Công cụ giúp cài đặt K3s dễ dàng hơn (nếu bạn dùng).
* **(Tùy chọn) Trình soạn thảo văn bản/IDE**: Ví dụ VS Code, vim.

---

## Hướng Dẫn Cài Đặt

### 1. Cài Đặt K3s Cluster

* **Trên Master Node:**

    ```bash
    # Ví dụ lệnh cài đặt K3s
    curl -sfL https://get.k3s.io | sh - 
    # Lấy token để join worker nodes
    sudo cat /var/lib/rancher/k3s/server/node-token
    ```

* **Trên Worker Nodes:**

    ```bash
    # Ví dụ lệnh join K3s worker
    curl -sfL https://get.k3s.io | K3S_URL=https://<MASTER_IP>:6443 K3S_TOKEN=<TOKEN_FROM_MASTER> sh -
    ```

* **Cấu hình `kubectl` trên máy quản lý của bạn:**
    Copy file `/etc/rancher/k3s/k3s.yaml` từ master node về máy của bạn tại `~/.kube/config`, hoặc merge vào file kubeconfig hiện có. Đảm bảo thay thế địa chỉ server `127.0.0.1` trong file `k3s.yaml` bằng địa chỉ IP thực của master node nếu bạn truy cập từ xa.

### 2. Cài Đặt MQTT Broker (EMQX)

1. Thêm Helm repository của EMQX:

    ```bash
    helm repo add emqx https://repos.emqx.io/charts
    helm repo update
    ```

2. Cài đặt EMQX:

    ```bash
    helm install emqx emqx/emqx \
      --namespace emqx \
      --create-namespace \
      -f helm_values/emqx/values.yaml
    ```

### 3. Cài Đặt Bộ Công Cụ Giám Sát

* **Prometheus:**

    ```bash
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    helm install prometheus prometheus-community/prometheus \
      --namespace prometheus \
      --create-namespace \
      -f helm_values/prometheus/values.yaml
    ```

* **Grafana:**

    ```bash
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo update
    helm install grafana grafana/grafana \
      --namespace grafana \
      --create-namespace \
      -f helm_values/grafana/values.yaml
    ```

* **Loki:**

    ```bash
    # (Grafana repo đã được thêm ở trên)
    helm install loki grafana/loki-stack \
      --namespace lokistack \
      --create-namespace \
      -f helm_values/loki/values.yaml
    ```

### 4. Cấu Hình Ingress

1. Đảm bảo Ingress Controller (Traefik) đang hoạt động trong cluster.
    * Nếu sử dụng Traefik cài đặt thủ công bằng Helm, đảm bảo nó đã được cài đặt và chạy.
    * Nếu muốn K3s tự cung cấp Traefik, hãy kiểm tra xem nó có đang chạy trong namespace `kube-system` không.
2. Cập nhật file `kubernetes_manifests/ingress/all-ingress.yaml` với các hostname mong muốn (ví dụ: `emqx.k3s.local`, `grafana.k3s.local`). Lưu ý chúng ta cần chỉnh lại subdomain này trong file hosts trong windows (*"C:\Windows\System32\drivers\etc\hosts"*)
3. Áp dụng Ingress:

    ```bash
    kubectl apply -f kubernetes_manifests/ingress/all-ingress.yaml
    ```

4. Cấu hình file `hosts` trên máy tính của bạn để trỏ các hostname đó đến địa chỉ IP của Ingress Controller (thường là IP của một trong các K3s node).
    Ví dụ (thay `<TRAEFIK_IP>` bằng IP thực tế):

```sh
    <TRAEFIK_IP> emqx.k3s.local
    <TRAEFIK_IP> grafana.k3s.local
    <TRAEFIK_IP> prometheus.k3s.local
    <TRAEFIK_IP> loki.k3s.local
```

### 5. Cấu Hình Egress (Network Policies)

Network Policies là một tính năng của Kubernetes cho phép bạn kiểm soát luồng traffic mạng ở tầng IP hoặc tầng port giữa các pod, cũng như giữa pod và các điểm cuối mạng khác (bao gồm cả bên ngoài cluster).

**Egress Policies** cụ thể cho phép bạn định nghĩa các quy tắc cho traffic **đi ra** từ các pod của bạn. Điều này rất quan trọng cho việc tăng cường bảo mật, ví dụ:

* Chỉ cho phép pod EMQX kết nối đến một database cụ thể bên ngoài.
* Ngăn chặn các pod trong một namespace nhất định kết nối ra internet, ngoại trừ một số địa chỉ IP hoặc domain được cho phép.
* Giới hạn communication giữa các namespace (ví dụ, chỉ cho phép namespace `app-frontend` nói chuyện với namespace `app-backend` trên các cổng nhất định).

**Lưu ý quan trọng:** Để Network Policies có hiệu lực, Network Plugin (CNI - Container Network Interface) trong cluster K3s của bạn phải hỗ trợ và thực thi chúng.

* Flannel (CNI mặc định của K3s trong nhiều trường hợp) **không** tự thực thi Network Policies. Để sử dụng Network Policies với Flannel, K3s cần được cài đặt với một backend khác cho Flannel (như `vxlan` với `flannel-cni-plugin` có hỗ trợ policy) hoặc bạn cần cài đặt một CNI khác hỗ trợ Network Policies như Calico, Canal, hoặc Weave Net.
* Nếu đã cài K3s mặc định và chưa cấu hình CNI đặc biệt, có thể Network Policies sẽ không được áp dụng. Hãy kiểm tra tài liệu của K3s hoặc CNI đang sử dụng.

---

## Truy Cập Các Dịch Vụ

Sau khi cài đặt và cấu hình Ingress/file hosts thành công:

* **EMQX Dashboard:** `http://emqx.k3s.local`
* **Grafana:** `http://grafana.k3s.local`
  * *Tài khoản mặc định thường là `admin`. Mật khẩu có thể lấy từ secret (`kubectl get secret --namespace grafana grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo`)*
* **Prometheus UI:** `http://prometheus.k3s.local`
* **Loki (truy cập qua Grafana datasource)**

---

## Cấu Trúc Thư Mục

```plaintext
.
├── .gitignore
├── README.md
├── helm_values/
│   ├── emqx/values.yaml
│   ├── grafana/values.yaml
│   ├── loki/values.yaml
│   └── prometheus/values.yaml
├── kubernetes_manifests/
│   ├── ingress/all-ingress.yaml
|   └── egress/all-egress.yaml
├── scripts/
│   ├── deploy_emqx.sh
│   ├── deploy_monitoring_stack.sh
│   └── initial_k3s_setup.sh
```
