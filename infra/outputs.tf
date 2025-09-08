output "manager_url" {
value = google_cloud_run_v2_service.manager.uri
}
output "service_account" {
value = google_service_account.gmo_app.email
}
output "artifact_repo" {
value = google_artifact_registry_repository.containers.repository_id
}
