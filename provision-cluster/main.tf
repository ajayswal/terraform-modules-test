resource "null_resource" "config_tiller" {
  provisioner "local-exec" {
    command = <<LOCAL_EXEC
    export KUBECONFIG="${data.terraform_remote_state.container-cluster.cluster_config_file_path}"
    kubectl create serviceaccount --namespace kube-system tiller
    kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
    kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
    helm init --service-account tiller --upgrade
    kubectl rollout status -w deployment/tiller-deploy --namespace=kube-system
    LOCAL_EXEC
  }
}

data "template_file" "prometheus-operator-values" {
  template = "${file("templates/prometheus-operator-values.yaml.tpl")}"

  vars {
    ingress_hostname       = "${data.terraform_remote_state.container-cluster.ingress_hostname}"
    ingress_secret         = "${data.terraform_remote_state.container-cluster.ingress_secret}"
    grafana_admin_password = "${var.grafana_admin_password}"
    create_before_destroy  = true
  }
}

resource "helm_repository" "ibm-chartmuseum" {
  name = "ibm-chartmuseum"
  url  = "https://registry.bluemix.net/helm/ibm/"
}

resource "helm_release" "ibm-worker-recovery" {
  name       = "ibm-worker-recovery"
  namespace  = "kube-system"
  chart      = "ibm-chartmuseum/ibm-worker-recovery"
  wait       = false
  depends_on = ["null_resource.config_tiller"]
}

resource "helm_release" "prometheus-operator" {
  name       = "prometheus-operator"
  namespace  = "prometheus-operator"
  chart      = "stable/prometheus-operator"
  wait       = false
  depends_on = ["null_resource.config_tiller"]

  values = [
    "${data.template_file.prometheus-operator-values.rendered}",
  ]
}

// Block storage plugin should be installed at the very end of 
// Terraform run since it restarts services, which drops Terraform 
// connection to the cluster and whole installation fails
resource "helm_release" "ibmcloud-block-storage-plugin" {
  name       = "ibmcloud-block-storage-plugin"
  namespace  = "kube-system"
  chart      = "ibm-chartmuseum/ibmcloud-block-storage-plugin"
  wait       = false
  depends_on = ["null_resource.config_tiller"]
}
