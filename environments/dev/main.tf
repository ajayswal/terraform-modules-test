module "dev" {
  source             = "../../modules/iks-cluster"
  space              = "dev"
  service            = "auth"
  team               = "b2c"
  org                = "coreeng@us.ibm.com"
  region             = "us-south"
  machine_type       = "b2c.4x16"
  zones              = ["dal10","dal12","dal13"]
  
  rabbitmq_plan          = "standard"
  rabbitmq_location      = "us-south"
  objectstorage_plan     = "standard"
  objectstorage_location = "global"
  
  multizone_pool_name          = "multizone"
  multizone_machine_type       = "u2c.2x4"
  multizone_hardware           = "shared"
  multizone_pool_size_per_zone = "2"
}
