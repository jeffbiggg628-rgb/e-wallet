output "artifact_registry_repo" {
  description = "Docker repo URL prefix for image pushes"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.wallet.repository_id}"
}

output "gke_cluster_name" {
  value = google_container_cluster.main.name
}

output "cloudsql_connection_name" {
  description = "Instance connection name used by the Cloud SQL Auth Proxy"
  value       = google_sql_database_instance.main.connection_name
}

output "wallet_db_password" {
  value     = random_password.wallet_db.result
  sensitive = true
}

output "wallet_app_sa_email" {
  value = google_service_account.wallet_app.email
}
