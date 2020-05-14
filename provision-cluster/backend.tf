terraform {
  backend "http" {
    # Serverless backend endpoint
    address        = "https://5eb41b45.us-south.apiconnect.appdomain.cloud/terraform/serverless/terraform-dev/cluster-provision"
    lock_address   = "https://5eb41b45.us-south.apiconnect.appdomain.cloud/terraform/serverless/terraform-dev/cluster-provision"
    unlock_address = "https://5eb41b45.us-south.apiconnect.appdomain.cloud/terraform/serverless/terraform-dev/cluster-provision"
    # Do not change the following
    username               = "cos"
    update_method          = "POST"
    lock_method            = "PUT"
    unlock_method          = "DELETE"
    skip_cert_verification = "false"
  }
}

data "terraform_remote_state" "container-cluster" {
  backend = "http"

  config {
    address  = "https://5eb41b45.us-south.apiconnect.appdomain.cloud/terraform/serverless/terraform-dev/cluster"
    username = "cos"
    password = "${var.backend_password}"
    skip_cert_verification = "false"
  }
}
