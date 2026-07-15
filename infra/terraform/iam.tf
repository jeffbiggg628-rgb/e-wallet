# Least-privilege service account for the wallet workload (PCA-style):
# the pod's Kubernetes SA impersonates this GCP SA via Workload Identity,
# and it can do exactly one thing — connect to Cloud SQL.
resource "google_service_account" "wallet_app" {
  account_id   = "wallet-app"
  display_name = "Wallet application workload identity"

  depends_on = [google_project_service.apis]
}

resource "google_project_iam_member" "wallet_cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.wallet_app.email}"
}

# Allow the KSA default/wallet to impersonate the GCP SA.
# The workload identity pool (<project>.svc.id.goog) only comes into existence
# when the project's first GKE cluster is created — bind after the cluster.
resource "google_service_account_iam_member" "wallet_workload_identity" {
  service_account_id = google_service_account.wallet_app.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[default/wallet]"

  depends_on = [google_container_cluster.main]
}
