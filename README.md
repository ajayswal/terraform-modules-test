IBM Cloud Terraform PoC
===
This example shows how multiple similar environments with minor differences can be managed with Hashicorp [Terraform](https://terraform.io) and IBM Cloud [Terraform Provider](https://ibm-cloud.github.io/tf-ibm-docs/index.html) for resource creation in IBM Cloud(multi-zone).

# What's inside

In this example we show how to reuse the same terraform code to create infrastructure for different environments using [modules](https://www.terraform.io/docs/configuration/modules.html). For each environment, we supply the values needed to configure the module for that environment.

Terraform is configured to store [state](https://www.terraform.io/docs/state/index.html) using [remote state](https://www.terraform.io/docs/state/remote.html) storage via IBM COS (S3 compatible backend). This allows people to collaborate on the same Terraform code base or run Terraform from a CI system as the state is stored remotely and accessible from a central location. In some cases Terraform state can be placed in a VCS, but since it contains sensitive information it is not recommended.

Terraform code provided within this repository will create the following resources:
* Kubernetes cluster in a multi-zone AZ 
* Basic IAM Configuration
* [COS storage](https://cloud.ibm.com/docs/services/cloud-object-storage/) AWS S3 compatible object storage
* [Messages for Rabbitmq](https://cloud.ibm.com/docs/services/messages-for-rabbitmq/index.html) Managed message queue
*  Service bindings to Kubernetes cluster (credential population via Kubernetes secret) for both RabbitMQ and COS
* Kubernetes cluster provisioning using [Helm](https://helm.sh) to install the following supplemental services from IBM and other public Helm chart repositories:
  * Worker recovery
  * IBM Block Storage
  * Prometheus Operator

# Preparing environment
* Configure [IBM Cloud CLI](https://pages.github.ibm.com/TheWeatherCompany/icm-docs/ibm-cloud-getting-started/cli-setup.html#ibm-cloud-cli-setup)
* Install Terraform using following [guide](https://learn.hashicorp.com/terraform/getting-started/install.html)
* Install IBM Cloud Terraform provider using following [guide](https://ibm-cloud.github.io/tf-ibm-docs/index.html#using-terraform-with-the-ibm-cloud-provider)
* Clone this code repository locally
* Configure Terraform remote state backend using one of the methods described below (etcdv3, http, or s3)

## Cloud specific variables
The Terraform provider for IBM Cloud needs credentials to access API's for resource creation. To configure credentials, export the API key as environment variable:

```
export BM_API_KEY="BMX_API_KEY"
export SL_USERNAME="SL_USERNAME"
export SL_API_KEY="SL_API_KEY"
```
Refer to the Terraform provider [documentation](https://ibm-cloud.github.io/tf-ibm-docs/#authentication) to see all available authentication options.

This repository ships Terraform code with default variable values, which will not work in most cases. Please change all settings to appropriate values before continuing. Variables and defined defaults (if any) are located in [variables.tf](modules/iks-cluster/variables.tf). All overrides and values for variables which are mandatory and don't have default values are configured to use different workspaces. An example of this is the dev configuration file: [dev/main.tf](https://github.ibm.com/TheWeatherCompany/icm-ibmcloud-terraform-poc/blob/master/environments/dev/main.tf).

Mandatory variables:

| variable          | description                        | get info with cli     |
| :---------------- | :--------------------------------- | :-------------------- |
| `org`             | IBM Cloud account datasource       | `ibmcloud iam orgs`   |
| `space`           | IBM Cloud CloudFoundry space       | `ibmcloud iam spaces` |
| `region`          | region for the worker nodes        | `ibmcloud cs regions` |
| `zone`            | datacenter for the worker nodes    | `ibmcloud cs zones`   |
| `public_vlan_id`  | public VLAN ID for the worker node | `ibmcloud cs vlans`   |
| `private_vlan_id` | private VLAN of the worker node    | `ibmcloud cs vlans`   |      |

#### How to create a [terraform module](https://www.terraform.io/docs/modules/index.html).

The [modules/iks-cluster]((https://github.ibm.com/TheWeatherCompany/icm-ibmcloud-terraform-poc/blob/master/modules/iks-cluster) directory contains an example module. This module is configured in each of the environment directories. 

The [iks-cluster/main.tf](https://github.ibm.com/TheWeatherCompany/icm-ibmcloud-terraform-poc/blob/master/modules/iks-cluster/main.tf) file will have the code, where the Terraform resources are declared.

An example usage of the module for the `dev` environment can be found here: [environments/dev/main.tf](https://github.ibm.com/TheWeatherCompany/icm-ibmcloud-terraform-poc/blob/master/environments/dev/main.tf)

```
module "dev" {
  source             = "../../modules/iks-cluster"
  ......
}
```
Note: Source path should match where all your resources files are.

Go ahead and add same code with the different module name for different Environments in [environments/qa/main.tf](https://github.ibm.com/TheWeatherCompany/icm-ibmcloud-terraform-poc/blob/master/environments/qa/main.tf) [environments/staging/main.tf](https://github.ibm.com/TheWeatherCompany/icm-ibmcloud-terraform-poc/blob/master/environments/staging/main.tf) [environments/production/main.tf](https://github.ibm.com/TheWeatherCompany/icm-ibmcloud-terraform-poc/blob/master/environments/production/main.tf)

```
module "qa" {
  source             = "../../modules/iks-cluster"
}
```

```
module "staging" {
  source             = "../../modules/iks-cluster"
}

```
```
module "production" {
  source              = "../../modules/iks-cluster"
}

```
#### How to Configure the Terraform Modules

We have setup our reusable modules, each environment might have its own requirements from a certain resource. In our example, production environments might need a bigger `machine_type` when compared to other environments. Alternatively, the `dev` environment might need more `worker_pool_zones` than others.

To solve this problem, we configure the modules using the input parameters. These are variables that are available in module's scope which are passed to module when it is called.

If the number of input variables grows, we need to have a [variable.tf](https://github.ibm.com/TheWeatherCompany/icm-ibmcloud-terraform-poc/blob/master/modules/iks-cluster/variables.tf) in the iks-cluster directory.

The [variable.tf](https://github.ibm.com/TheWeatherCompany/icm-ibmcloud-terraform-poc/blob/master/modules/iks-cluster/variables.tf) will have the input parameters which configures the module.

```
variable "space" {}
variable "org" {}
variable "region" {}

```

The module uses the variables for its configuration as show in [modules/iks-cluster/main.tf](https://github.ibm.com/TheWeatherCompany/icm-ibmcloud-terraform-poc/blob/master/modules/iks-cluster/main.tf)

```
data "ibm_org" "org" {
  org = "${var.org}"
}

// Define datasource for CF space
data "ibm_space" "space"{
  org         = "${var.org}"
  space       = "${var.space}"
  }

```
In each of the environment main.tf files, the module now needs these variables defined and passed to it. Here is an example of how dev could be configured: [environment/dev/main.tf ](https://github.ibm.com/TheWeatherCompany/icm-ibmcloud-terraform-poc/blob/master/environments/dev/main.tf) looks like:

```hcl
  module "dev" {
    source             = "../../modules/iks-cluster"
    space              = "dev"
    service            = "auth"
    team               = "b2c"
    org                = "coreeng@us.ibm.com"
    region             = "us-south"
    machine_type       = "b2c.4x16"
    zones              = ["dal10","dal12","dal13"]s
    
    rabbitmq_plan          = "standard"
    rabbitmq_location      = "us-south"
    objectstorage_plan     = "standard"
    objectstorage_location = "global"
    
    multizone_pool_name          = "multizone"
    multizone_machine_type       = "u2c.2x4"
    multizone_hardware           = "shared"
    multizone_pool_size_per_zone = "2"
}
 
```
[environment/staging/main.tf ](https://github.ibm.com/TheWeatherCompany/icm-ibmcloud-terraform-poc/blob/master/environments/staging/main.tf),
[environment/qa/main.tf ](https://github.ibm.com/TheWeatherCompany/icm-ibmcloud-terraform-poc/blob/master/environments/qa/main.tf),
[environment/production/main.tf ](https://github.ibm.com/TheWeatherCompany/icm-ibmcloud-terraform-poc/blob/master/environments/production/main.tf)

Finally, if we need to setup the infrastructure for dev we need to do the following steps:
1. Initialize terraform with exported environment variables:
```
cd environments/dev
terraform init
```
```
terraform plan
```
2. Validate output for any errors or misconfiguration, fix them, re-run plan. If everything is looking good, proceed with actual resource creation:
```
terraform apply

```
3. Terraform should bring up an iks-cluster in dev environment by running `terraform plan` and `terraform apply`.

> To setup the infrastructure for "qa", "staging" and "production". Run the above recommended steps after entering into the respective environment directory.


# Terraform multi-zone cluster implementation

If you want to implement the multi-zone cluster, create a single zone cluster, add an additional zone and attach it to the specified worker pool using [worker_pool_zone_attachment resource](https://ibm-cloud.github.io/tf-ibm-docs/v0.17.1/r/container_worker_pool_zone_attachment.html) in the main.tf file where the resource for the container cluster is declared [modules/iks-cluster/main.tf](https://github.ibm.com/TheWeatherCompany/icm-ibmcloud-terraform-poc/blob/master/modules/iks-cluster/main.tf).

```hcl
resource "ibm_container_worker_pool" "multizone" {
  worker_pool_name  = "${var.multizone_pool_name}"
  machine_type      = "${var.multizone_machine_type}"
  cluster           = "${ibm_container_cluster.iks-cluster.id}"
  size_per_zone     = "${var.multizone_pool_size_per_zone}"
  hardware          = "${var.multizone_hardware}"
  region            = "${var.region}"
  resource_group_id = "${data.ibm_resource_group.resource-group.id}"

labels = {
  "test"  = "pool"
  "test1" = "pool1"
  }
}

```
above, we initiate the resource `ibm_container_worker_pool` and pass the input variables like worker_pool_name, machine type, region and we pass how many worker nodes per zone. 


```hcl
resource "ibm_container_worker_pool_zone_attachment" "multizone" {
  count             = "${length(var.zones)}"
 
  cluster           = "${ibm_container_cluster.iks-cluster.id}"
  worker_pool       = "${element(split("/",ibm_container_worker_pool.multizone.id),1)}"
  zone              = "${var.zones[count.index]}"
  private_vlan_id   = "${ibm_network_vlan.private.*.id[count.index]}"
  public_vlan_id    = "${ibm_network_vlan.public.*.id[count.index]}"
  region            = "${var.region}"
  resource_group_id = "${data.ibm_resource_group.resource-group.id}"

  timeouts {
      create = "90m"
      update = "90m"
      delete = "90m"
   }
  }

```
The above configuration creates zone attachments for the specified worker pool by referencing the worker_pool property. The number of zones to create is determined by counting up the list of zones provided by the "zones" variable and placing the result in the count [`count`](https://www.terraform.io/docs/configuration/resources.html#count-multiple-resource-instances) property. It creates a one for each zone and attaches it to the specified worker pool.



## Terraform remote state 
Terraform offers several [backend types](https://www.terraform.io/docs/backends/types/index.html). This Terraform example shows three possible solutions for remote state storage backends:
 * [**etcdv3**](https://www.terraform.io/docs/backends/types/etcdv3.html) backend
 * [**http**](https://www.terraform.io/docs/backends/types/http.html) backend
 * [**s3**](https://www.terraform.io/docs/backends/types/s3.html) backend

Currently, ETCD is the most fully featured and easiest solution for Terraform remote state storage. If state locking is not required, COS service is the best and simpliest option.

Recent Terraform versions include [Postgres](https://www.terraform.io/docs/backends/types/pg.html) Database backend. While it is compatible with IBM [Databases for PostgreSQL](https://cloud.ibm.com/docs/services/databases-for-postgresql), it can't provide desired level of state isolation because can't store more than one state per database (only one database is allowed per PostgreSQL instance). All that being said, we can't recommend using PostgreSQL backend.

### ETCD remote state backend
IBM Cloud provides managed [Databases for ETCD](https://cloud.ibm.com/catalog/services/databases-for-etcd), which is compatible with Terraform [etcdv3](
https://www.terraform.io/docs/backends/types/etcdv3.html) backend. 

#### Request ETCD instance
Request ETCD instance using IBM Cloud CLI using following command:
```sh
ibmcloud resource service-instance-create <instance-name> databases-for-etcd <plan> <region>
```
For example, create ETCD instance with name `terraform-etcd-backend` and `Standard` service plan in `us-south` region (name will be used in further commands):
```sh
ibmcloud resource service-instance-create terraform-etcd-backend databases-for-etcd standard us-south
```
Follow deployment progress:
```sh
ibmcloud resource service-instance terraform-etcd-backend
```
Once fully deployed, create new access credentials using following command:
```sh
ibmcloud resource service-key-create terraform-etcd-backend-key Administrator --instance-name terraform-etcd-backend
```

#### Configure Terraform `etcdv3` backend
After service key is created you can get credentials using following commands (assuming [`jq`](https://stedolan.github.io/jq/) is installed):
Get instance hostname and port:
```sh
ibmcloud resource service-key terraform-etcd-backend-key --output=json | jq .[0].credentials.connection.grpc.hosts
```
Fill connection info into `backend.tf` file:
```hcl
terraform {
  backend "etcdv3" {
    endpoints = ["https://<hostname>:<port>"]
  }
}
```
Get username and password:
```sh
ibmcloud resource service-key terraform-etcd-backend-key --output=json | jq .[0].credentials.connection.grpc.authentication
```
and export them as environment variables:
```sh
export ETCDV3_USERNAME=<username>
export ETCDV3_PASSWORD=<password>
```
And finally get CA certificate used for SSL connection validation:
```sh
ibmcloud resource service-key terraform-etcd-backend-key --output=json | jq --raw-output .[0].credentials.connection.grpc.certificate.certificate_base64 | base64 -D
```
Save PEM encoded certificate output to file and import in **System CA store** (e.g. **System** Keychain on MacOS or default trusted CA store in Linux). This step is required, otherwise Terraform will not be able to validate self-signed certificate provided by ETCD service.

Then initialize Terraform using the above exported environment variables:
```sh
terraform init
```

### Serverless remote state backend
This project provides an implementation of the REST backend using serverless [IBM Cloud Functions](https://console.bluemix.net/openwhisk) and [IBM Cloud Object Storage](https://console.bluemix.net/catalog/services/cloud-object-storage) with **optional [state locking](https://www.terraform.io/docs/state/locking.html)** and **versioning** of Terraform states.

#### Deploy the serverless backend
Serverless function code is located under [serverless-state-backend](serverless-state-backend) folder

Copy `local.env.example` file to `local.env` and fill the blanks with the information described below.
Assuming that the COS Resource instance that you created in the [Preparing environment](#preparing-environment) step is called `icm-terraform`, use the following CLI commands to get the resource's details:
```sh
ibmcloud resource service-instance icm-terraform 
```
Assign `ID` field contents for `STORAGE_RESOURCE_INSTANCE_ID` variable

`STORAGE_API_ENDPOINT` variable will depend on the region where COS bucket is created, for instance `s3.us.cloud-object-storage.appdomain.cloud`

`VERSIONING` variable configures if Terraform state versioning will be enabled. If set to `true`, each previous Terraform state will be saved prior storing new one in the bucket.

Deploy the serverless backend action using provided script:
   ```sh
   ./deploy.sh --install
   ```
Expose the action with API Gateway:
   ```sh
   ./deploy.sh --installApi
   ```
Record created API Gateway endpoint URL

#### Configure Terraform `http` backend
Use following code as reference to configure Terraform backend:
```hcl
terraform {
  backend "http" {
    # Serverless backend endpoint
    address = "<FUNCTION_API_URL>/<BUCKET_NAME>/<ENV_NAME>"

    # Optional locking, coment out to disable. Should be set to same value as address
    lock_address   = "<FUNCTION_API_URL>/<BUCKET_NAME>/<ENV_NAME>"
    unlock_address = "<FUNCTION_API_URL>/<BUCKET_NAME>/<ENV_NAME>"

    # API Key for Cloud Object Storage will be passed in as partial backend configuration during Terraform init
    // password = 

    # Do not change the following
    username               = "cos"
    update_method          = "POST"
    lock_method            = "PUT"
    unlock_method          = "DELETE"
    skip_cert_verification = "false"
  }
}
```
Use API Gateway endpoint URL as `FUNCTION_API_URL` created on previous step. `BUCKET_NAME` allows operator to specify bucket name COS service, bucket should be created before it can be used.
`ENV_NAME` parameter is optional, it allows operator to provide virtual path within the bucket , (e.g `dev/us-south/my-app`) to store multiple Terraform state files. If empty, `terraform.tfstate` will be stored without _prefix_.

To avoid checking passwords into git, export it as follows:
```
export TF_VAR_backend_password=<API_KEY>
```

To get API key for COS service use following command:
```sh
ibmcloud resource service-key terraform-dev
```
where `terraform-dev` is the service key for the COS service

Then initialize Terraform using the above exported environment variables:

```bash
terraform init -backend-config="password=$TF_VAR_backend_password"
```

### S3 Backend (IBM COS)
IBM Cloud provides AWS S3 compatible object storage - IBM [Cloud Object Storage](https://cloud.ibm.com/docs/services/cloud-object-storage). It's very simple and easy to configure backend, but since state locking with S3 backend uses AWS DynamoDB tables, locking is not available with COS. Using Terraform S3 backend with COS is advised when Terraform state locking is not required. 

To prepare COS service to be used as Terraform remote state backend:
* Create COS storage service, bucket and credentials for Terraform state storage [Getting started](https://cloud.ibm.com/docs/services/cloud-object-storage/getting-started.html#getting-started-console-)
* Make sure you have enabled [HMAC credentials generation](https://cloud.ibm.com/docs/services/cloud-object-storage/hmac?topic=cloud-object-storage-service-credentials#using-hmac-credentials)
* Retrive `access_key` and `secret_key` from created service credentials

Now you can export there credentials as environment variables:
```sh
export AWS_ACCESS_KEY_ID="<access key>"
export AWS_SECRET_ACCESS_KEY="<secret key>"
```

#### Configure Terraform `S3` backend
Once credentials are configured, proceed with Terrafrom backend configuration. Provide COS bucket access details in your `backend.tf` file. Specifically `bucket`, `key` and region specific variables:

```hcl
terraform {
  backend "s3" {
    bucket                      = "<bucket_name>"
    key                         = "<optional_key_path>/terraform.tfstate"
    region                      = "us-geo"
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_get_ec2_platforms      = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    endpoint                    = "s3.us.cloud-object-storage.appdomain.cloud"
  }
}
```

Then initialize Terraform with remote state storage using the above exported environment variables:
```sh
terraform init 
```

## Adding cloud services
IBM Cloud Terraform provider can manage two types of cloud services via `service_instance` and `resource_instance` resources. Main diffrence between them is that `service_instance` is backed by CloudFoundry, while `resource_instance` is more "cloud native" managed services. Some services may appear in both categories of services, for instance RabbitMQ. In such cases we recommend using `resource_instance` if it's available.

To add new cloud service, discover available offerings via IBM Marketplace:
```bash
ibmcloud catalog service-marketplace
```
pick desired service and gather available options for service request:
```bash
ibmcloud catalog service <servicename>
```
Refer to [resource_instance](https://ibm-cloud.github.io/tf-ibm-docs/v0.14.1/r/resource_instance.html) section in IBM Cloud Terraform Provider documentation to create Terraform resource for new service. 
We provide an example on how [Messages for RabbitMQ](https://cloud.ibm.com/docs/services/messages-for-rabbitmq/index.html#about-messages-for-rabbitmq) `resource_instance` can be created. It can be found in [iks-cluster/services.tf](https://github.ibm.com/TheWeatherCompany/icm-ibmcloud-terraform-poc/blob/master/modules/iks-cluster/services.tf) file. 

# Applying configuration
Terraform code for cluster creation and cluster provisioning is split into two separate code bases. This is necessary because providers are initialized at the beginning of Terraform run and Helm and Kubernetes cannot target a non-existent Kubernetes cluster. To workaround this behavior, cluster creation and provisioning are run sequentially using remote state data source to get cluster access details for Helm and Kubernetes providers.

Alternatively, insted of using code splitting, cluster provisioning code can be added later to the same code base, once the cluster is already created (for instance - merged in as PR).

## Create cloud resources with Terraform

Here you can create the cloud resources with respect to the environment, If you want to create it for 'dev' :
```
cd environments/dev
terraform init
terraform plan
```
Validate output for any errors or misconfiguration, fix them, re-run plan. If everything is looking good, proceed with actual resource creation:
```
terraform apply
```

## Provision additional software and configuration
Make sure that remote state data source defined in [provision-cluster/backend.tf](provision-cluster/backend.tf) points to the correct bucket and key used during cluster creation in the previous step as it is required for Helm to target the correct cluster for software installation.

While IBM Worker recovery and IBM Block Storage Helm charts are installed without any configuration, the Prometheus Operator can be configured very precisely.

To configure the Prometheus Operator, you use Terraform to generate a `values.yaml` file. This file will be used by Helm to configure the installation of the Prometheus Operator into the cluster.  To see what values can be configured, look at the Prometheus Operator's [values.yaml](https://github.com/helm/charts/blob/master/stable/prometheus-operator/values.yaml). An example Terraform template that generates the override values in a `values.yaml` file is [provision-cluster/templates/prometheus-operator-values.yaml.tpl](provision-cluster/templates/prometheus-operator-values.yaml.tpl).

The example template obtains both the ingress hostname and ingress TLS secret name with TLS certificates via a Terraform data source attached to the remote Terraform state for the cluster.

After everything is configured correctly, proceed with provisioning:
```
cd provision-cluster
terraform plan
```
Validate output for any errors or misconfiguration, fix them, re-run plan. If everything is looking good, proceed with actual resource creation:
```
terraform apply
```

# Upgrading Kubernetes clusters
It is possible to upgrade Kubernetes cluster managed by Terraform. To trigger cluster upgrade, operator could change cluster version in resource definition. In this example this can be achieved by changing or setting `kube_version` variable in [icm-ibmcloud-terraform-poc/modules/iks-cluster/variables.tf](https://github.ibm.com/TheWeatherCompany/icm-ibmcloud-terraform-poc/blob/master/modules/iks-cluster/variables.tf) file.

If version is changed, Terraform will trigger cluster upgrade during next `terraform apply` run.

By default, only control plane is upgraded. To upgrade worker nodes, operator can perform such operation either manually during desired maintanence window or automatically after control plane upgrade. To enable automatic rolling upgrade of workers, parameter `update_all_workers` should be set to `true` in [icm-ibmcloud-terraform-poc/modules/iks-cluster/variables.tf](https://github.ibm.com/TheWeatherCompany/icm-ibmcloud-terraform-poc/blob/master/modules/iks-cluster/variables.tf) file.

# Cleaning up
Terraform is capable of removing resources it is managing. To delete everything that has been created on previous steps.
Clean up resources and state managed by Helm and Kubernetes providers:
```
cd provision-cluster
terraform destroy
```
and finally all cloud resources:
```
cd environments/dev
terraform destroy
```
