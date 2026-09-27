# Create Yandex Container Registry
resource "yandex_container_registry" "diploma_registry" {
  name      = "${var.project_name}-registry"
  folder_id = var.folder_id
  
  labels = {
    project = var.project_name
    env     = "diploma"
  }
}

# Optional but recommended: Grant pull access to the Service Account created in stage0
# This allows your Kubernetes cluster to pull images without hardcoded docker credentials
# Note: Replace 'your-bootstrap-sa-id' with the actual SA ID from stage0 outputs, 
# or manage this binding manually via YC Console if cross-stage references are complex.
/*
resource "yandex_container_registry_iam_binding" "puller" {
  registry_id = yandex_container_registry.diploma_registry.id
  role        = "container-registry.images.puller"
  
  members = [
    "serviceAccount:YOUR_STAGE0_SA_ID_HERE",
  ]
}
*/