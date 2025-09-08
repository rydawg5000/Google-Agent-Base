terraform {


# --- Secret Manager placeholder ---
resource "google_secret_manager_secret" "app" {
secret_id = "gmo-app-config"
replication { auto {} }
}


# --- Logging sinks to GCS + BQ ---
resource "google_logging_project_sink" "to_gcs" {
name = "to-gcs"
destination = "storage.googleapis.com/${google_storage_bucket.core_logs.name}"
filter = "resource.type=\"cloud_run_revision\""
}


resource "google_logging_project_sink" "to_bq" {
name = "to-bq"
destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${google_bigquery_dataset.core.dataset_id}"
filter = "resource.type=\"cloud_run_revision\""
}


# --- Minimal Cloud Run (Manager) placeholder ---
resource "google_cloud_run_v2_service" "manager" {
name = "manager-agent"
location = var.region
template {
containers {
image = "${google_artifact_registry_repository.containers.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.containers.repository_id}/manager:latest"
env {
name = "REGION"
value = var.region
}
env { name = "BQ_DATASET" value = google_bigquery_dataset.core.dataset_id }
}
service_account = google_service_account.gmo_app.email
}
ingress = "INGRESS_ALL"
}


# --- IAM bindings (minimal) ---
resource "google_project_iam_member" "run_invoker_all" {
project = var.project_id
role = "roles/run.invoker"
member = "serviceAccount:${google_service_account.gmo_app.email}"
}


resource "google_project_iam_member" "bq_user" {
project = var.project_id
role = "roles/bigquery.user"
member = "serviceAccount:${google_service_account.gmo_app.email}"
}


resource "google_project_iam_member" "firestore_user" {
project = var.project_id
role = "roles/datastore.user"
member = "serviceAccount:${google_service_account.gmo_app.email}"
}


resource "google_project_iam_member" "aiplatform_user" {
project = var.project_id
role = "roles/aiplatform.user"
member = "serviceAccount:${google_service_account.gmo_app.email}"
}
