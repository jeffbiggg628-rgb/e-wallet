resource "google_artifact_registry_repository" "wallet" {
  repository_id = "e-wallet"
  location      = var.region
  format        = "DOCKER"
  description   = "Container images for the e-wallet services"

  depends_on = [google_project_service.apis]
}
