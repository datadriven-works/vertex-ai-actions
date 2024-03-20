provider "google" {
  project = var.project_id
}

module "project-services" {
  source                      = "terraform-google-modules/project-factory/google//modules/project_services"
  version                     = "14.2.1"
  disable_services_on_destroy = false

  project_id  = var.project_id
  enable_apis = true

  activate_apis = [
    "secretmanager.googleapis.com", 
    "cloudfunctions.googleapis.com",
    "cloudbuild.googleapis.com",
    "aiplatform.googleapis.com",
  ]
}

resource "google_secret_manager_secret" "sendgrid_api_key" {
  project     = var.project_id
  secret_id   = "SENDGRID_API_KEY"
  replication {
    user_managed {
      replicas {
        location = var.deployment_region
      }
    }
  }
}

resource "google_secret_manager_secret" "looker_auth_token" {
  project     = var.project_id
  secret_id   = "LOOKER_AUTH_TOKEN"
  replication {
    user_managed {
      replicas {
        location = var.deployment_region
      }
    }
  }
}


resource "google_service_account" "vertex_ai_actions_cloud_function" {
  project      = var.project_id
  account_id   = "vertex-ai-actions"
  display_name = "Vertex AI Actions Cloud Functions"
}

resource "google_project_iam_binding" "cloudfunctions_invoker" {
  project = var.project_id
  role    = "roles/cloudfunctions.invoker"

  members = [
    "serviceAccount:${google_service_account.vertex_ai_actions_cloud_function.email}",
  ]
}

resource "google_project_iam_binding" "aiplatform_user" {
  project = var.project_id
  role    = "roles/aiplatform.user"

  members = [
    "serviceAccount:${google_service_account.vertex_ai_actions_cloud_function.email}",
  ]
}

resource "google_project_iam_binding" "secretmanager_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"

  members = [
    "serviceAccount:${google_service_account.vertex_ai_actions_cloud_function.email}",
  ]
}

resource "google_secret_manager_secret_iam_binding" "sendgrid_api_key_accessor" {
  secret_id = google_secret_manager_secret.sendgrid_api_key.secret_id
  role      = "roles/secretmanager.secretAccessor"
  members   = [
    "serviceAccount:${google_service_account.vertex_ai_actions_cloud_function.email}",
  ]
}

resource "google_secret_manager_secret_iam_binding" "looker_auth_token_accessor" {
  secret_id = google_secret_manager_secret.looker_auth_token.secret_id
  role      = "roles/secretmanager.secretAccessor"
  members   = [
    "serviceAccount:${google_service_account.vertex_ai_actions_cloud_function.email}",
  ]
}