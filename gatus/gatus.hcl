locals {
  image = "ghcr.io/twin/gatus:v5.21.0"
}

job "gatus" {
  group "gatus" {
    network {
      port "gatus" {
        to           = 8080
        host_network = "private"
      }
    }

    task "gatus" {
      driver = "podman"

      service {
        name         = "status"
        port         = "gatus"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["public"]
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      template {
        data        = file("config.yml.tpl")
        destination = "/local/config.yml"
      }

      env {
        GATUS_CONFIG_PATH = "/local/config.yml"
      }

      config {
        image = "${local.image}"
        ports = ["gatus"]

        logging = {
          driver = "journald"
        }
      }
    }
  }
}
