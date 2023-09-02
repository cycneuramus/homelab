locals {
  strg = pathexpand("~/cld/wizarr")
}

job "wizarr" {
  constraint {
    attribute = "${meta.performance}"
    value     = "high"
  }

  group "wizarr" {
    count = 1

    network {
      port "http" {
        to           = 5690
        host_network = "private"
      }
    }

    task "wizarr" {
      driver = "docker"
      user   = "1000:1000"

      service {
        name     = "wizarr"
        port     = "http"
        provider = "nomad"
        tags     = ["public", "monitor"]
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      config {
        image = "ghcr.io/wizarrrr/wizarr"
        ports = ["http"]

        mount {
          type   = "bind"
          source = "${local.strg}/data"
          target = "/data/database"
        }
      }
    }
  }
}
