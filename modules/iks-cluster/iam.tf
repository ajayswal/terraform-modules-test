
resource "ibm_iam_access_group" "admin" {
  name        = "${var.team}_administrator"
  description = "${var.team} access group which has 'Administrator' access to resource groups for the team"
}


resource "ibm_iam_access_group_policy" "admin" {
  access_group_id = "${ibm_iam_access_group.admin.id}"
  roles           = ["Administrator"]

  resources = [
    {
		 resource_type = "resource-group"
		 resource      = "${data.ibm_resource_group.resource-group.id}"
    }, 
  ] 
}

resource "ibm_iam_access_group" "iks_admin" {
  name        = "${var.team}_IKS_admin"
  description = "${var.team} access group which has 'Editor', 'Operator', 'Viewer'  and 'Administrator' access to the kubernetes clusters for the team "
}

resource "ibm_iam_access_group_policy" "iks_admin" {
  access_group_id = "${ibm_iam_access_group.iks_admin.id}"
  roles           = ["Editor", "Operator", "Viewer", "Administrator"]

  resources = [
    {
      service              = "containers-kubernetes"
      resource_instance_id = "${ibm_container_cluster.iks-cluster.id}"
    },
  ]
}

resource "ibm_iam_access_group" "cos_admin" {
  name        = "${var.team}_COS_admin_group"
  description = "${var.team} access group which has 'Viewer', 'Operator, 'Editor'  and 'Administrator' as well as 'Manager', 'Writer' and 'Reader' access permissions for COS services for the team"
}

resource "ibm_iam_access_group_policy" "cos_admin" {
  access_group_id = "${ibm_iam_access_group.cos_admin.id}"
  roles           = ["Viewer", "Operator", "Editor", "Administrator", "Manager", "Writer", "Reader"]

  resources = [
    {
      service              = "cloud-object-storage"
      resource_instance_id = "${ibm_resource_instance.objectstorage.id}"
    },
  ]
}
