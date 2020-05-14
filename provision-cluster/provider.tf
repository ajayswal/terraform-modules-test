provider "external" {}
provider "null" {}
provider "random" {}
provider "local" {}
provider "template" {}

provider "helm" {
  //debug = true

  kubernetes {
    config_path = "${data.terraform_remote_state.container-cluster.cluster_config_file_path}"
  }
}

provider "kubernetes" {
  config_path = "${data.terraform_remote_state.container-cluster.cluster_config_file_path.value}"
}
