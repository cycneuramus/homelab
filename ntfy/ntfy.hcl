locals {
  strg = pathexpand("~/cld/ntfy")
}

job "ntfy" {
  constraint {
    attribute = "${meta.performance}"
    value     = "high"
  }

  group "ntfy" {
    count = 1

    network {
      port "http" {
        to           = 80
        host_network = "private"
      }
    }

    task "ntfy" {
      driver = "docker"
      user   = "1000:1000"

      service {
        name     = "ntfy"
        port     = "http"
        provider = "nomad"
        tags     = ["local", "monitor"]
      }

      template {
        data        = file("server.yml")
        destination = "server.yml"
      }

      env {
        TZ = "Europe/Stockholm"
      }

      config {
        image = "binwiederhier/ntfy"
        ports = ["http"]

        command = "serve"

        mount {
          type   = "bind"
          source = "server.yml"
          target = "/etc/ntfy/server.yml"
        }

        mount {
          type   = "bind"
          source = "${local.strg}/cache"
          target = "/var/cache/ntfy"
        }
      }
    }
  }
}
