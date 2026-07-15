# Autopilot: Google manages nodes; we pay per pod resource request.
# deletion_protection is off on purpose — this cluster lives in an
# apply-verify-destroy cycle (plan: minimal-cost strategy).
resource "google_container_cluster" "main" {
  name     = "e-wallet"
  location = var.region

  enable_autopilot    = true
  deletion_protection = false

  depends_on = [google_project_service.apis]
}
