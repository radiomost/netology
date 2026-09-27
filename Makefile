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

# Get kubeconfig from master node (Fixed for TLS certificate validation)
k8s-kubeconfig:
	@echo "=== DEBUG: Проверяем, видит ли shell директорию ==="
	@ls -ld ./stage2-compute
	@echo "=== Fetching kubeconfig from master node ==="
	@cd ./stage2-compute && terraform init -input=false > /dev/null
	@MASTER_IP=$$(cd ./stage2-compute && terraform output -raw master_external_ip) && \
	MASTER_INT_IP=$$(cd ./stage2-compute && terraform output -raw master_internal_ip) && \
	echo "Master External IP: $$MASTER_IP" && \
	echo "Master Internal IP: $$MASTER_INT_IP" && \
	mkdir -p ~/.kube && \
	ssh -o StrictHostKeyChecking=no -o ConnectTimeout=15 -i ~/.ssh/id_rsa ubuntu@$$MASTER_IP \
		"sudo cp /root/.kube/config /tmp/kubeconfig && sudo chown ubuntu:ubuntu /tmp/kubeconfig" && \
	scp -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa ubuntu@$$MASTER_IP:/tmp/kubeconfig ~/.kube/config && \
	ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa ubuntu@$$MASTER_IP "rm -f /tmp/kubeconfig" && \
	sed -i "s|https://$$MASTER_INT_IP:6443|https://127.0.0.1:6443|g" ~/.kube/config && \
	sed -i "s|https://$$MASTER_IP:6443|https://127.0.0.1:6443|g" ~/.kube/config && \
	chmod 600 ~/.kube/config && \
	echo "Kubeconfig saved to ~/.kube/config and configured for localhost tunnel." && \
	echo "To connect, run: ssh -i ~/.ssh/id_rsa -f -N -L 6443:$$MASTER_INT_IP:6443 ubuntu@$$MASTER_IP" && \
	echo "Then test with: kubectl get nodes"

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
	@echo "=== Building and pushing Docker image to Yandex Container Registry ==="
	@echo "App: $(APP_NAME), Version: $(APP_VERSION)"

	@ls -la

	# Step 1: Get registry_id from Terraform output
	echo "[1/6] Fetching registry ID from Terraform..."
	REGISTRY_ID=$$(cd stage3-registry && terraform output -raw registry_id 2>/dev/null)
	if [ -z "$$REGISTRY_ID" ]; then
		echo "Error: registry_id not found. Run 'terraform apply' in stage3-registry first."
		exit 1
	fi
	echo "Registry ID: $$REGISTRY_ID"
	
	# Step 2: Clone or update application repository
	echo "[2/6] Preparing application source code..."
	if [ ! -d "$(APP_DIR)" ]; then
		echo "Cloning repository from $(APP_REPO_URL)..."
		git clone $(APP_REPO_URL) $(APP_DIR)
	else
		echo "Repository already exists. Pulling latest changes..."
		cd $(APP_DIR) && git pull origin main && cd ..
	fi
	
	# Step 3: Authenticate Docker with Yandex Container Registry
	echo "[3/6] Authenticating Docker with YCR..."
	YCR_TOKEN=$$(yc iam create-token 2>/dev/null)
	if [ -z "$$YCR_TOKEN" ]; then
		echo "Error: Failed to get IAM token. Is 'yc' CLI installed and authorized?"
		exit 1
	fi
	echo "$$YCR_TOKEN" | docker login --username iam --password-stdin cr.yandex
	
	# Step 4: Build Docker image
	echo "[4/6] Building Docker image..."
	cd $(APP_DIR)
	docker build -t cr.yandex/$$REGISTRY_ID/$(APP_NAME):$(APP_VERSION) .
	docker build -t cr.yandex/$$REGISTRY_ID/$(APP_NAME):latest .
	cd ..
	
	# Step 5: Push image to YCR
	echo "[5/6] Pushing image to Yandex Container Registry..."
	docker push cr.yandex/$$REGISTRY_ID/$(APP_NAME):$(APP_VERSION)
	docker push cr.yandex/$$REGISTRY_ID/$(APP_NAME):latest
	
	# Step 6: Cleanup
	echo "[6/6] Cleaning up local images..."
	docker rmi cr.yandex/$$REGISTRY_ID/$(APP_NAME):$(APP_VERSION) 2>/dev/null || true
	docker rmi cr.yandex/$$REGISTRY_ID/$(APP_NAME):latest 2>/dev/null || true
	
	echo ""
	echo "=== Build complete! ==="
	echo "Image: cr.yandex/$$REGISTRY_ID/$(APP_NAME):$(APP_VERSION)"
	echo "To deploy in K8s, use this image in your Deployment manifest."

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

# Get kubeconfig from master node
# =============================================================================
# Kubernetes Deployment (Monitoring & App) - CLEAN VERSION
# =============================================================================

KUBECONFIG_DIR := $(PWD)/stage2-compute
REGISTRY_DIR := $(PWD)/stage3-registry

k8s-kubeconfig:
	@echo "=== Fetching kubeconfig from master node ==="
	@ls -la $(KUBECONFIG_DIR)
	@cd $(KUBECONFIG_DIR) && terraform init -input=false > /dev/null
	@MASTER_IP=$$(cd $(KUBECONFIG_DIR) && terraform output -raw master_external_ip) && \
	MASTER_INT_IP=$$(cd $(KUBECONFIG_DIR) && terraform output -raw master_internal_ip) && \
	echo "Master External IP: $$MASTER_IP" && \
	echo "Master Internal IP: $$MASTER_INT_IP" && \
	mkdir -p ~/.kube && \
	ssh -o StrictHostKeyChecking=no -o ConnectTimeout=15 -i ~/.ssh/id_rsa ubuntu@$$MASTER_IP \
		"sudo cp /root/.kube/config /tmp/kubeconfig && sudo chown ubuntu:ubuntu /tmp/kubeconfig" && \
	scp -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa ubuntu@$$MASTER_IP:/tmp/kubeconfig ~/.kube/config && \
	ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa ubuntu@$$MASTER_IP "rm -f /tmp/kubeconfig" && \
	sed -i "s|https://$$MASTER_INT_IP:6443|https://127.0.0.1:6443|g" ~/.kube/config && \
	sed -i "s|https://$$MASTER_IP:6443|https://127.0.0.1:6443|g" ~/.kube/config && \
	chmod 600 ~/.kube/config && \
	echo "Kubeconfig saved to ~/.kube/config and configured for localhost tunnel."

k8s-deploy:
	@echo "=== Deploying Monitoring Stack and Application ==="
	@ls -la $(REGISTRY_DIR)
	@cd $(REGISTRY_DIR) && terraform init -input=false > /dev/null
	@REGISTRY_ID=$$(cd $(REGISTRY_DIR) && terraform output -raw registry_id) && \
	echo "Detected Registry ID: $$REGISTRY_ID" && \
	echo "[1/5] Adding Helm repositories..." && \
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts && \
	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx && \
	helm repo update && \
	echo "[2/5] Installing NGINX Ingress Controller..." && \
	helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
		--namespace ingress-nginx --create-namespace \
		--set controller.replicaCount=1 \
		--set controller.hostNetwork=true \
		--set controller.dnsPolicy=ClusterFirstWithHostNet \
		--set controller.service.type=ClusterIP \
		--set controller.nodeSelector."kubernetes\.io/os"=linux && \
	echo "[3/5] Installing kube-prometheus-stack..." && \
	helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
		--namespace monitoring --create-namespace \
		-f stage4-k8s-configs/monitoring-values.yaml && \
	echo "[4/5] Creating YCR pull secret..." && \
	ycr_token=$$(yc iam create-token | tr -d '\n\r') && \
	kubectl create secret docker-registry ycr-secret \
		--docker-server=cr.yandex \
		--docker-username=iam \
		--docker-password="$$ycr_token" \
		-n default --dry-run=client -o yaml | kubectl apply -f - && \
	echo "[5/5] Deploying test application..." && \
	sed "s|__REGISTRY_ID__|$$REGISTRY_ID|g" stage4-k8s-configs/app-deployment.yaml | kubectl apply -f - && \
	kubectl apply -f stage4-k8s-configs/app-service.yaml && \
	kubectl apply -f stage4-k8s-configs/app-ingress.yaml && \
	echo "" && \
	echo "=== Waiting for pods to be ready ===" && \
	kubectl wait --for=condition=ready pod -l app=netology-diploma-app --timeout=120s -n default || true && \
	echo "" && \
	echo "=== Deployment Complete! ==="


# Uninstall everything from the cluster
k8s-destroy:
	@echo "=== Destroying Kubernetes resources ==="
	@kubectl delete -f stage4-k8s-configs/app-ingress.yaml || true
	@kubectl delete -f stage4-k8s-configs/app-service.yaml || true
	@kubectl delete -f stage4-k8s-configs/app-deployment.yaml || true
	@helm uninstall monitoring --namespace monitoring || true
	@echo "Done."