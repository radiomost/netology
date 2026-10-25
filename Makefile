ENV_MODE ?= local

ifeq ($(ENV_MODE),ci)
	MODE_MESSAGE := Запущен режим сборки Gitlab CI
else
	MODE_MESSAGE := Запущен локальный режим сборки
endif


.PHONY: init plan apply destroy clean

# Default target
help:
	@echo "Kubernetes Cluster Deployment Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  make init      - Initialize all terraform stages"
	@echo "  make plan      - Plan all terraform stages"
	@echo "  make apply     - Apply all terraform stages"
	@echo "  make destroy   - Destroy all terraform stages (in reverse order)"
	@echo "  make clean     - Remove local .terraform directories"
	@echo "  make build     - Build and push Docker image"
	@echo "  make k8s-deploy- Deploy monitoring and app to K8s"
	@echo ""

# Define stages in dependency order (for apply) and reverse order (for destroy)
STAGES_APPLY = stage0-bootstrap stage1-network stage2-compute stage3-registry
STAGES_DESTROY = stage3-registry stage2-compute stage1-network stage0-bootstrap

init:
	@for stage in $(STAGES_APPLY); do \
		if [ -d "$$stage" ]; then \
			echo "==> Initializing $$stage..."; \
			(cd "$$stage" && terraform init) || exit 1; \
		else \
			echo "==> Skipping $$stage (directory not found)"; \
		fi; \
	done

plan:
	@for stage in $(STAGES_APPLY); do \
		if [ -d "$$stage" ]; then \
			echo "==> Planning $$stage..."; \
			(cd "$$stage" && terraform init -reconfigure && terraform plan) || exit 1; \
		else \
			echo "==> Skipping $$stage (directory not found)"; \
		fi; \
	done

apply:
	@for stage in $(STAGES_APPLY); do \
		if [ -d "$$stage" ]; then \
			echo "==> Applying $$stage..."; \
			(cd "$$stage" && terraform init -reconfigure && terraform apply -auto-approve) || exit 1; \
		else \
			echo "==> Skipping $$stage (directory not found)"; \
		fi; \
	done

destroy:
	@for stage in $(STAGES_DESTROY); do \
		if [ -d "$$stage" ]; then \
			echo "==> Processing $$stage..."; \
			if [ "$$stage" = "stage3-registry" ]; then \
				echo "==> Cleaning up container repositories first..."; \
				REGISTRY_ID=$$(cd stage3-registry && terraform output -raw registry_id 2>/dev/null || echo ""); \
				if [ -n "$$REGISTRY_ID" ]; then \
					yc container repository delete --name "$$REGISTRY_ID/netology-diploma-app" --async 2>/dev/null || true; \
				fi; \
			fi; \
			(cd "$$stage" && terraform init -reconfigure && terraform destroy -auto-approve) || exit 1; \
		else \
			echo "==> Skipping $$stage (directory not found)"; \
		fi; \
	done

clean:
	@echo "==> Cleaning up local terraform files..."
	@for stage in $(STAGES_APPLY); do \
		if [ -d "$$stage" ]; then \
			rm -rf "$$stage/.terraform" "$$stage/.terraform.lock.hcl"; \
		fi; \
	done
	@echo "Done."

# Перед установкой kuberspray необходимо в ручную через  WebUI консоль YandexCloud
# Удалить автоматически назначенные IP адреса и заменить их на подготовленные "белые" IP

# Initialize Kubespray
kubespray-init:
	@echo "=== Initializing Kubespray ==="
	@./scripts/setup-kubespray.sh

# Generate inventory only (if Kubespray is already initialized)
kubespray-inventory:
	@echo "=== Regenerating Ansible Inventory ==="
	@if [ ! -d "kubespray" ]; then \
		echo "Error: Kubespray not initialized. Run 'make kubespray-init' first."; \
		exit 1; \
	fi
	@./scripts/setup-kubespray.sh
	@echo "Inventory regenerated at kubespray/inventory/mycluster/hosts.yaml"
# Deploy Kubernetes cluster
kubespray-deploy:
	@echo "=== Deploying Kubernetes Cluster ==="
	@if [ ! -f "kubespray/inventory/mycluster/hosts.yaml" ]; then \
		echo "Error: Inventory not found. Run 'make kubespray-init' first."; \
		exit 1; \
	fi
	@cd kubespray && \
		ansible-playbook -i inventory/mycluster/hosts.yaml \
			-u ubuntu \
			-b --become-user=root \
			--private-key=~/.ssh/id_rsa \
			cluster.yml
	@echo "Kubernetes cluster deployed successfully!"

# Reset Kubespray (remove and start fresh)
kubespray-reset:
	@echo "=== Resetting Kubespray ==="
	@read -p "This will remove the kubespray directory. Continue? [y/N] " confirm && \
		[ $$confirm = "y" ] || [ $$confirm = "Y" ] || exit 1
	@rm -rf kubespray
	@echo "Kubespray removed. Run 'make kubespray-init' to start fresh."


# ============================================================
# Docker Image Build & Push to Yandex Container Registry
# ============================================================
# .ONESHELL:
# Variables (can be overridden via command line: make build APP_VERSION=v2.0.0)
APP_NAME        ?= netology-diploma-app
APP_VERSION     ?= v1.0.0
APP_REPO_URL    ?= git@github.com:radiomost/netology-diploma-app.git
APP_DIR         := app-source

# Build, tag and push Docker image to YCR
build:
	@echo "=== Building and pushing Docker image to Yandex Container Registry ===" && \
	echo "App: $(APP_NAME), Version: $(APP_VERSION)" && \
	echo "[1/6] Fetching registry ID from Terraform..." && \
	REGISTRY_ID=$$(cd stage3-registry && terraform output -raw registry_id 2>/dev/null) && \
	if [ -z "$$REGISTRY_ID" ]; then \
		echo "Error: registry_id not found. Run 'terraform apply' in stage3-registry first."; \
		exit 1; \
	fi && \
	echo "Registry ID: $$REGISTRY_ID" && \
	echo "[2/6] Preparing application source code..." && \
	if [ ! -d "$(APP_DIR)" ]; then \
		echo "Cloning repository from $(APP_REPO_URL)..."; \
		git clone $(APP_REPO_URL) $(APP_DIR); \
	else \
		echo "Repository already exists. Pulling latest changes..."; \
		cd $(APP_DIR) && git pull origin main && cd ..; \
	fi && \
	echo "[3/6] Authenticating Docker with YCR..." && \
	grep -v '"yc"' ~/.docker/config.json > ~/.docker/config.json.tmp 2>/dev/null && mv ~/.docker/config.json.tmp ~/.docker/config.json || true && \
	YCR_TOKEN=$$(yc iam create-token 2>/dev/null) && \
	if [ -z "$$YCR_TOKEN" ]; then \
		echo "Error: Failed to get IAM token. Is 'yc' CLI installed and authorized?"; \
		exit 1; \
	fi && \
	echo "$$YCR_TOKEN" | docker login --username iam --password-stdin cr.yandex && \
	echo "[4/6] Building Docker image..." && \
	cd $(APP_DIR) && \
	docker build -t cr.yandex/$$REGISTRY_ID/$(APP_NAME):$(APP_VERSION) . && \
	docker build -t cr.yandex/$$REGISTRY_ID/$(APP_NAME):latest . && \
	cd .. && \
	echo "[5/6] Pushing image to Yandex Container Registry..." && \
	docker push cr.yandex/$$REGISTRY_ID/$(APP_NAME):$(APP_VERSION) && \
	docker push cr.yandex/$$REGISTRY_ID/$(APP_NAME):latest && \
	echo "[6/6] Cleaning up local images..." && \
	docker rmi cr.yandex/$$REGISTRY_ID/$(APP_NAME):$(APP_VERSION) 2>/dev/null || true && \
	docker rmi cr.yandex/$$REGISTRY_ID/$(APP_NAME):latest 2>/dev/null || true && \
	echo "" && \
	echo "=== Build complete! ===" && \
	echo "Image: cr.yandex/$$REGISTRY_ID/$(APP_NAME):$(APP_VERSION)"

# Clean up cloned application source
clean-app:
	@echo "Removing application source directory..."
	@rm -rf $(APP_DIR)
	@echo "Done."


# =============================================================================
# Variables
# =============================================================================
# Динамически получаем Registry ID из Terraform state
REGISTRY_ID := $(shell cd stage3-registry && terraform output -raw registry_id 2>/dev/null || echo "REPLACE_ME_VIA_TERRAFORM")

KUBECONFIG_DIR := $(PWD)/stage2-compute
REGISTRY_DIR := $(PWD)/stage3-registry
K8S_TUNNEL_PORT := 6443

# =============================================================================
# Kubernetes Configuration & Tunnel
# =============================================================================

# Копирование kubeconfig с мастер-ноды
k8s-kubeconfig:
	@echo "=== Fetching kubeconfig from master node ==="
	@ls -la $(KUBECONFIG_DIR)
	@cd $(KUBECONFIG_DIR) && terraform init -input=false > /dev/null
	@MASTER_IP=$$(cd $(KUBECONFIG_DIR) && terraform output -raw master_external_ip) && \
	MASTER_INT_IP=$$(cd $(KUBECONFIG_DIR) && terraform output -raw master_internal_ip) && \
	echo "Master External IP: $$MASTER_IP" && \
	echo "Master Internal IP: $$MASTER_INT_IP" && \
	mkdir -p ~/.kube && \
	echo "Copying kubeconfig via SSH..." && \
	ssh -o StrictHostKeyChecking=no -o ConnectTimeout=15 -i ~/.ssh/id_rsa ubuntu@$$MASTER_IP \
		"sudo cat /etc/kubernetes/admin.conf" > ~/.kube/config && \
	chmod 600 ~/.kube/config && \
	echo "Updating server address to use SSH tunnel (127.0.0.1:$(K8S_TUNNEL_PORT))..." && \
	sed -i "s|https://$$MASTER_INT_IP:6443|https://127.0.0.1:$(K8S_TUNNEL_PORT)|g" ~/.kube/config && \
	sed -i "s|https://$$MASTER_IP:6443|https://127.0.0.1:$(K8S_TUNNEL_PORT)|g" ~/.kube/config && \
	sed -i "s|https://localhost:6443|https://127.0.0.1:$(K8S_TUNNEL_PORT)|g" ~/.kube/config && \
	echo "✓ Kubeconfig saved to ~/.kube/config and configured for localhost tunnel." && \
	echo "" && \
	echo "Next step: Run 'make k8s-tunnel' to create SSH tunnel"

# Создание SSH-туннеля к мастер-ноде
k8s-tunnel:
	@echo "=== Creating SSH tunnel to K8s master ==="
	@cd $(KUBECONFIG_DIR) && terraform init -input=false > /dev/null
	@MASTER_IP=$$(cd $(KUBECONFIG_DIR) && terraform output -raw master_external_ip) && \
	echo "Master External IP: $$MASTER_IP" && \
	echo "Checking if port $(K8S_TUNNEL_PORT) is already in use..." && \
	if ss -tulnp 2>/dev/null | grep -q ":$(K8S_TUNNEL_PORT) "; then \
		echo "Warning: Port $(K8S_TUNNEL_PORT) is already in use."; \
		echo "Stopping existing tunnels..."; \
		pkill -f "ssh.*$(K8S_TUNNEL_PORT)" 2>/dev/null || true; \
		sleep 2; \
	fi && \
	echo "Creating SSH tunnel: localhost:$(K8S_TUNNEL_PORT) -> master:6443" && \
	ssh -i ~/.ssh/id_rsa -f -N -L $(K8S_TUNNEL_PORT):127.0.0.1:6443 ubuntu@$$MASTER_IP && \
	echo "✓ SSH tunnel created successfully in background" && \
	echo "" && \
	echo "Verify connection with: make k8s-check"

# Остановка SSH-туннеля
k8s-stop-tunnel:
	@echo "=== Stopping SSH tunnel ==="
	@pkill -f "ssh.*$(K8S_TUNNEL_PORT)" 2>/dev/null && echo "✓ SSH tunnel stopped" || echo "No active tunnel found"

# Проверка подключения к Kubernetes кластеру
k8s-check:
	@echo "=== Checking Kubernetes cluster connection ==="
	@echo "Testing kubectl connectivity..."
	@kubectl cluster-info
	@echo ""
	@echo "Listing cluster nodes:"
	@kubectl get nodes -o wide
	@echo ""
	@echo "Listing all pods:"
	@kubectl get pods --all-namespaces
	@echo ""
	@echo "✓ Kubernetes cluster is accessible"

# Полный цикл: конфиг + туннель + проверка
k8s-setup: k8s-kubeconfig k8s-tunnel k8s-check
	@echo ""
	@echo "=== K8s setup complete ==="
	@echo "You can now run: make k8s-deploy"

# =============================================================================
# Kubernetes Deployment (Monitoring & App) - IMPROVED VERSION
# =============================================================================

.PHONY: k8s-deploy
k8s-deploy:
	@echo "=== Deploying Monitoring Stack and Application ==="
	@echo "[0/5] Checking Kubernetes cluster connection..."
	@if ! kubectl cluster-info > /dev/null 2>&1; then \
		echo "❌ Error: Cannot connect to Kubernetes cluster."; \
		echo "Please run: make k8s-ci-connect (or k8s-setup locally)"; \
		exit 1; \
	fi
	@echo "✓ Cluster is reachable. Proceeding..."

	@echo "[1/5] Fetching Registry ID from Terraform state..."
	@cd $(REGISTRY_DIR) && terraform init -input=false -backend=false > /dev/null 2>&1 || true
	@REGISTRY_ID=$$(cd $(REGISTRY_DIR) && terraform output -raw registry_id 2>/dev/null || echo "YOUR_REGISTRY_ID_HERE") && \
	echo "Detected Registry ID: $$REGISTRY_ID" && \
	echo "[2/5] Adding Helm repositories..." && \
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true && \
	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx || true && \
	helm repo update > /dev/null && \
	echo "[3/5] Installing NGINX Ingress Controller (with Cloud LoadBalancer)..." && \
	helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
		--namespace ingress-nginx --create-namespace \
		--set controller.replicaCount=1 \
		--set controller.service.type=LoadBalancer \
		--set controller.service.annotations."service\.beta\.kubernetes\.io/yandex-cloud-lb-type"="external" \
		--set controller.nodeSelector."kubernetes\.io/os"=linux \
		--wait && \
	echo "[4/5] Installing kube-prometheus-stack..." && \
	helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
		--namespace monitoring --create-namespace \
		-f stage4-k8s-configs/monitoring-values.yaml \
		--wait && \
	echo "[5/5] Creating YCR pull secret..." && \
	ycr_token=$$(yc iam create-token | tr -d '\n\r') && \
	kubectl create secret docker-registry ycr-secret \
		--docker-server=cr.yandex \
		--docker-username=iam \
		--docker-password="$$ycr_token" \
		-n default --dry-run=client -o yaml | kubectl apply -f - && \
	echo "Deploying test application..." && \
	sed "s|__REGISTRY_ID__|$$REGISTRY_ID|g" stage4-k8s-configs/app-deployment.yaml | kubectl apply -f - && \
	kubectl apply -f stage4-k8s-configs/app-service.yaml && \
	kubectl apply -f stage4-k8s-configs/app-ingress.yaml && \
	echo "" && \
	echo "=== Waiting for pods to be ready ===" && \
	kubectl wait --for=condition=ready pod -l app=netology-diploma-app --timeout=120s -n default || true && \
	echo "" && \
	echo "=== Deployment Complete! ==="

	@echo ""
	@echo "🎉 Access points:"
	@echo "Waiting for LoadBalancer to assign an external IP..."
	@sleep 5
	@LB_IP=$$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null) && \
	if [ -n "$$LB_IP" ]; then \
		echo "  🌐 Grafana:  http://$$LB_IP/grafana (admin/prom-operator)"; \
		echo "  🌐 App:      http://$$LB_IP/"; \
	else \
		echo "  ⏳ LoadBalancer is still provisioning. Check with: kubectl get svc -n ingress-nginx"; \
	fi
	
# =============================================================================
# Cleanup
# =============================================================================

# Uninstall everything from the cluster
k8s-destroy:
	@echo "=== Destroying Kubernetes resources ==="
	@kubectl delete -f stage4-k8s-configs/app-ingress.yaml 2>/dev/null || true
	@kubectl delete -f stage4-k8s-configs/app-service.yaml 2>/dev/null || true
	@kubectl delete -f stage4-k8s-configs/app-deployment.yaml 2>/dev/null || true
	@helm uninstall monitoring --namespace monitoring 2>/dev/null || true
	@helm uninstall ingress-nginx --namespace ingress-nginx 2>/dev/null || true
	@kubectl delete namespace monitoring 2>/dev/null || true
	@kubectl delete namespace ingress-nginx 2>/dev/null || true
	@echo "✓ All Kubernetes resources removed"

# ==============================================================================
# CI/CD SPECIFIC TARGETS
# ==============================================================================

.PHONY: k8s-ci-connect
# ==============================================================================
# УСЛОВИЕ ДЛЯ CI (GitLab)
# ==============================================================================
ifeq ($(ENV_MODE),ci)
k8s-ci-connect:
	@echo "Запущен режим сборки Gitlab CI"
	@echo "=== CI/CD: Настройка безопасного подключения к K8s API ==="
	
	@# Получаем IP-адреса напрямую через terraform output
	@cd stage2-compute && \
	MASTER_EXT_IP=$$(terraform output -raw master_external_ip) && \
	MASTER_INT_IP=$$(terraform output -raw master_internal_ip) && \
	echo "Master External IP: $$MASTER_EXT_IP" && \
	echo "Master Internal IP: $$MASTER_INT_IP" && \
	cd .. && \
	$(MAKE) k8s-kubeconfig MASTER_EXTERNAL_IP=$$MASTER_EXT_IP MASTER_INTERNAL_IP=$$MASTER_INT_IP
	
	@echo "Запуск SSH туннеля в фоновом режиме..."
	@cd stage2-compute && \
	MASTER_EXT_IP=$$(terraform output -raw master_external_ip) && \
	MASTER_INT_IP=$$(terraform output -raw master_internal_ip) && \
	cd .. && \
	(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -f -N -L 6443:127.0.0.1:6443 ubuntu@$$MASTER_EXT_IP || \
	ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -f -N -L 6443:$$MASTER_INT_IP:6443 ubuntu@$$MASTER_EXT_IP)
	
	@echo "Ожидание 3 секунды для стабилизации туннеля..."
	@sleep 3
	
	@echo "Проверка подключения к кластеру..."
	@kubectl cluster-info
	
	@echo "✓ Подключение к K8s успешно установлено!"

# ==============================================================================
# УСЛОВИЕ ДЛЯ ЛОКАЛЬНОЙ РАЗРАБОТКИ
# ==============================================================================
else
k8s-ci-connect:
	@echo "Запущен локальный режим сборки"
	@echo "=== Локальная настройка безопасного подключения к K8s API ==="
	
	@# 1. Получаем и модифицируем kubeconfig
	@$(MAKE) k8s-kubeconfig
	
	@echo "Запуск SSH туннеля в фоновом режиме..."
	@# 2. Пытаемся пробросить порт. (Обратите внимание: используем ubuntu@, а не root@)
	@ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -f -N -L 6443:127.0.0.1:6443 ubuntu@$(MASTER_EXTERNAL_IP) || \
	(echo "Туннель на 127.0.0.1 не прошел. Пробуем внутренний IP $(MASTER_INTERNAL_IP)..." && \
	ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -f -N -L 6443:$(MASTER_INTERNAL_IP):6443 ubuntu@$(MASTER_EXTERNAL_IP))
	
	@echo "Ожидание 3 секунды для стабилизации туннеля..."
	@sleep 3
	
	@echo "Проверка подключения к кластеру..."
	@kubectl cluster-info
	
	@echo "✓ Подключение к K8s успешно установлено!"
endif

.PHONY: k8s-kubeconfig-deploy
k8s-kubeconfig-deploy:
	@echo "=== Fetching kubeconfig from master node ==="
	@echo "DEBUG 1: Проверяем содержимое /etc/kubernetes/ на мастер-ноде..."
	@ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$(MASTER_EXTERNAL_IP) "ls -la /etc/kubernetes/ || echo 'ПАПКА /etc/kubernetes/ ОТСУТСТВУЕТ!'"
	
	@echo "DEBUG 2: Ищем файл admin.conf в системе..."
	@ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$(MASTER_EXTERNAL_IP) "find / -name 'admin.conf' -type f 2>/dev/null | head -n 5 || echo 'ФАЙЛ admin.conf НЕ НАЙДЕН НИГДЕ!'"

	@echo "Copying kubeconfig via SSH..."
	@# Пытаемся скопировать. Если файла нет, команда завершится с ошибкой, и мы это увидим.
	@ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$(MASTER_EXTERNAL_IP) "cat /etc/kubernetes/admin.conf" > ~/.kube/config
	
	@echo "Updating server address to use SSH tunnel (127.0.0.1:6443)..."
	@sed -i.bak 's|server: https://.*|server: https://127.0.0.1:6443|g' ~/.kube/config
	@echo "✓ Kubeconfig saved to ~/.kube/config and configured for localhost tunnel."