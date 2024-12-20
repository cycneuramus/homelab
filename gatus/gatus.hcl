locals {
  version = "v5.14.0"
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
        # change_mode = "noop"
      }

      env {
        GATUS_CONFIG_PATH = "/local/config.yml"
      }

      config {
        image = "ghcr.io/twin/gatus:${local.version}"
        ports = ["gatus"]

        logging = {
          driver = "journald"
        }
      }
    }
  }
}
