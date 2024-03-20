resource "random_string" "random" {
  length  = 3
  special = false
  lower   = true
  upper   = false
}

resource "google_storage_bucket" "bucket-source" {
  name          = "looker-genai-${var.project_id}"
  location      = "us"
  uniform_bucket_level_access = true
  force_destroy = true
}

# Generate the File to upload go GCS for Cloud Function
data "archive_file" "default" {
  type        = "zip"
  output_path = "/tmp/function-source.zip"
  source_dir  = "../"
}

# Bucket with source code for Cloud Function
resource "google_storage_bucket_object" "functions_vertex_action" {
  name   = "vertex_action_code.zip"
  bucket = google_storage_bucket.bucket-source.name
  source =  data.archive_file.default.output_path
  depends_on = [ data.archive_file.default]
}


resource "google_cloudfunctions_function" "vertex_ai_list" {
  name                  = "vertex-ai-list"
  description           = "Vertex AI list function"
  runtime               = "python311"
  available_memory_mb   = 256
  timeout               = 540
  entry_point           = "action_list"
  trigger_http          = true

  source_archive_bucket = google_storage_bucket.bucket-source.name
  source_archive_object = google_storage_bucket_object.functions_vertex_action.name

  environment_variables = {
    ACTION_LABEL = "Vertex AI"
    ACTION_NAME = "vertex-ai"
    REGION = var.deployment_region
    PROJECT = var.project_id
    EMAIL_SENDER = "no-reply@datadriven.works"
  }

  project = var.project_id
  region  = var.deployment_region

  https_trigger_security_level = "SECURE_ALWAYS"
  service_account_email = google_service_account.vertex_ai_actions_cloud_function.email

  secret_environment_variables {
    key = "LOOKER_AUTH_TOKEN"
    secret = google_secret_manager_secret.looker_auth_token.secret_id
    version = "latest"
  }
}

resource "google_cloudfunctions_function_iam_member" "vertex_ai_list_unauthenticated" {
  project        = var.project_id
  region         = var.deployment_region
  cloud_function = google_cloudfunctions_function.vertex_ai_list.name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}

resource "google_cloudfunctions_function" "vertex_ai_form" {
  name                  = "vertex-ai-form"
  description           = "Vertex AI form function"
  runtime               = "python311"
  available_memory_mb   = 256
  timeout               = 540
  entry_point           = "action_form"
  trigger_http          = true
  https_trigger_security_level = "SECURE_ALWAYS"

  source_archive_bucket = google_storage_bucket.bucket-source.name
  source_archive_object = google_storage_bucket_object.functions_vertex_action.name

  environment_variables = {
    ACTION_LABEL = "Vertex AI"
    ACTION_NAME = "vertex-ai"
    REGION = var.deployment_region
    PROJECT = var.project_id
    EMAIL_SENDER = "no-reply@datadriven.works"
  }

  project = var.project_id
  region  = var.deployment_region

  service_account_email = google_service_account.vertex_ai_actions_cloud_function.email

  secret_environment_variables {
    key = "LOOKER_AUTH_TOKEN"
    secret = google_secret_manager_secret.looker_auth_token.secret_id
    version = "latest"
  }
}

resource "google_cloudfunctions_function_iam_member" "vertex_ai_form_unauthenticated" {
  project        = var.project_id
  region         = var.deployment_region
  cloud_function = google_cloudfunctions_function.vertex_ai_form.name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}

resource "google_cloudfunctions_function" "vertex_ai_execute" {
  name                  = "vertex-ai-execute"
  description           = "Vertex AI execute function"
  runtime               = "python311"
  available_memory_mb   = 1024
  timeout               = 540
  entry_point           = "action_execute"
  trigger_http          = true
  https_trigger_security_level = "SECURE_ALWAYS"

  source_archive_bucket = google_storage_bucket.bucket-source.name
  source_archive_object = google_storage_bucket_object.functions_vertex_action.name

  environment_variables = {
    ACTION_LABEL = "Vertex AI"
    ACTION_NAME = "vertex-ai"
    REGION = var.deployment_region
    PROJECT = var.project_id
    EMAIL_SENDER = "no-reply@datadriven.works"
  }

  project = var.project_id
  region  = var.deployment_region

  service_account_email = google_service_account.vertex_ai_actions_cloud_function.email

  secret_environment_variables {
    key = "LOOKER_AUTH_TOKEN"
    secret = google_secret_manager_secret.looker_auth_token.secret_id
    version = "latest"
  }

  secret_environment_variables {
    key = "SENDGRID_API_KEY"
    secret = google_secret_manager_secret.sendgrid_api_key.secret_id
    version = "latest"
  }
}

resource "google_cloudfunctions_function_iam_member" "vertex_ai_execute_unauthenticated" {
  project        = var.project_id
  region         = var.deployment_region
  cloud_function = google_cloudfunctions_function.vertex_ai_execute.name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}
