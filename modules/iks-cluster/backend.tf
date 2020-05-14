
terraform {
  backend "etcdv3" {
    endpoints = ["https://d40fe7b8a-3a35-4d00-8a7e-0425123956de.b8a5e798d2d04f2e860e54e5d042c915.databases.appdomain.cloud:32588"]
    lock      = true
    prefix    = ""
  }
}
