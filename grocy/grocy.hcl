locals {
  strg    = pathexpand("~/cld/grocy")
  version = "latest"
}

job "grocy" {
  constraint {
    attribute = "${meta.performance}"
    value     = "high"
  }

  group "grocy" {
    count = 1

    network {
      port "http" {
        to           = 80
        host_network = "private"
      }
    }

    task "grocy" {
      driver = "docker"

      service {
        name     = "grocy"
        port     = "http"
        provider = "nomad"
        tags     = ["public"]
      }

      env {
        PUID = "1000"
        PGID = "1000"
        TZ   = "Europe/Stockholm"
      }

      config {
        image = "linuxserver/grocy:${local.version}"
        ports = ["http"]

        mount {
          type   = "bind"
          source = "${local.strg}/config"
          target = "/config"
        }
      }
    }
  }
}
