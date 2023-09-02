locals {
  strg = pathexpand("~/cld/gatus")
}

job "gatus" {
  group "gatus" {
    count = 1

    network {
      port "gatus" {
        to           = 8080
        host_network = "private"
      }
    }

    task "gatus" {
      driver = "docker"

      service {
        name     = "status"
        port     = "gatus"
        provider = "nomad"
        tags     = ["local"]
      }

      template {
        data        = file("config.yml.tpl")
        destination = "/local/config.yml"
      }

      env {
        GATUS_CONFIG_PATH = "/local/config.yml"
      }

      config {
        image = "twinproduction/gatus:stable"
        ports = ["gatus"]
      }
    }
  }
}
