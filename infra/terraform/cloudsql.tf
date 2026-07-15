resource "random_password" "wallet_db" {
  length  = 24
  special = false
}

# Smallest viable MySQL 8 instance; no HA, minimal disk, no deletion
# protection — apply-verify-destroy cycle. Access goes through the
# Cloud SQL Auth Proxy (IAM-gated), so no authorized networks are opened.
resource "google_sql_database_instance" "main" {
  name             = "e-wallet-mysql"
  database_version = "MYSQL_8_0"
  region           = var.region

  deletion_protection = false

  settings {
    tier              = "db-f1-micro"
    availability_type = "ZONAL"
    disk_type         = "PD_HDD"
    disk_size         = 10
  }

  depends_on = [google_project_service.apis]
}

resource "google_sql_database" "wallet" {
  name     = "wallet"
  instance = google_sql_database_instance.main.name
}

resource "google_sql_user" "wallet" {
  name     = "wallet"
  instance = google_sql_database_instance.main.name
  password = random_password.wallet_db.result
}
