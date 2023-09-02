locals {
  strg = pathexpand("~/cld/terraforming-mars")
}

job "terraforming-mars" {
  constraint {
    attribute = "${meta.performance}"
    value     = "high"
  }

  constraint {
    attribute = "${attr.cpu.arch}"
    operator  = "!="
    value     = "arm64"
  }

  group "terraforming-mars" {
    count = 1

    network {
      port "http" {
        to           = 8765
        host_network = "private"
      }
    }

    task "terraforming-mars" {
      driver = "docker"
      user   = "1000:1000"

      service {
        name     = "tm"
        port     = "http"
        provider = "nomad"
        tags     = ["public", "monitor"]
      }

      env {
        NODE_ENV = "production"
        PORT     = "8765"
      }

      config {
        image = "ltdstudio/terraforming-mars"
        ports = ["http"]

        mount {
          type   = "bind"
          source = "${local.strg}/db"
          target = "/usr/src/app/db"
        }
      }
    }
  }
}
