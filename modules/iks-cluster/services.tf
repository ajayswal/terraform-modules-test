// Creates RabbitMQ service with standard plan
// In this example default parameters are also adjusted to show how it can be done
resource "ibm_resource_instance" "rabbitmq" {
  name              = "${var.team}-${var.service}-${var.space}-iks-rabbitmq"
  service           = "messages-for-rabbitmq"
  plan              = "${var.rabbitmq_plan}"
  location          = "${var.rabbitmq_location}"
  resource_group_id = "${data.ibm_resource_group.resource-group.id}"

  parameters = {
    "members_memory_allocation_mb" = "6144"
    "members_disk_allocation_mb"   = "30720"
  }

  tags = ["${var.team}","rabbitmq"]
}

// Creates binding of RabbitMQ service into k8s cluster
// Creates a secret with connection details in desired namespace in target cluster
resource "ibm_container_bind_service" "rabbitmq-iks-bind" {
  cluster_name_id     = "${ibm_container_cluster.iks-cluster.id}"
  space_guid          = "${data.ibm_space.space.id}"
  service_instance_id = "${ibm_resource_instance.rabbitmq.name}"
  namespace_id        = "default"
  org_guid            = "${data.ibm_org.org.id}"
  resource_group_id   = "${data.ibm_resource_group.resource-group.id}"
}

// Creates Object storage
resource "ibm_resource_instance" "objectstorage" {
  name              = "${var.team}-${var.service}-${var.space}-rabbitmq-os"
  service           = "cloud-object-storage"
  plan              = "${var.objectstorage_plan}"
  location          = "${var.objectstorage_location}"
  resource_group_id = "${data.ibm_resource_group.resource-group.id}"
}

// Creates binding of cloud object storage into cluster and namespace
resource "ibm_container_bind_service" "objectstorage-iks-bind" {
  cluster_name_id     = "${ibm_container_cluster.iks-cluster.id}"
  space_guid          = "${data.ibm_space.space.id}"
  service_instance_id = "${ibm_resource_instance.objectstorage.name}"
  namespace_id        = "default"
  org_guid            = "${data.ibm_org.org.id}"
  resource_group_id   = "${data.ibm_resource_group.resource-group.id}"
}
