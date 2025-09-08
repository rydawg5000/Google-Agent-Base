variable "project_id" { type = string }
variable "region" { type = string default = "europe-west4" }
variable "bq_location" { type = string default = "EU" }
variable "firestore_location" { type = string default = "europe-west4" }
variable "bq_dataset_id" { type = string default = "pvo_core_analytics" }
