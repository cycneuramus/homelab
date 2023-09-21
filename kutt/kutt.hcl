locals {
  strg = pathexpand("~/cld/kutt")
}

job "kutt" {
  constraint {
    attribute = "${meta.performance}"
    value     = "high"
  }

  group "kutt" {
    count = 1

    network {
      port "app" {
        to           = 3000
        host_network = "private"
      }

      port "redis" {
        to           = 6379
        host_network = "private"
      }
    }

    task "app" {
      driver = "docker"

      service {
        name     = "kutt"
        port     = "app"
        provider = "nomad"
        tags     = ["private"]
      }

      template {
        data        = file("env_app")
        destination = "env_app"
        env         = true
      }

      config {
        image = "kutt/kutt"
        ports = ["app"]

        command = "./wait-for-it.sh"
        args    = ["${attr.unique.network.ip-address}:15432", "--", "npm", "start"]
      }
    }

    task "redis" {
      driver = "docker"

      config {
        image = "redis:alpine"
        ports = ["redis"]
      }
    }
  }
}
