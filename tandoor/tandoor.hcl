locals {
  image = "ghcr.io/tandoorrecipes/recipes:2.0.3"
  strg  = "/mnt/jfs/tandoor"
}

job "tandoor" {
  group "tandoor" {
    network {
      port "web" {
        to           = 80
        host_network = "private"
      }
    }

    task "tandoor" {
      driver = "podman"

      resources {
        memory_max = 2048
      }

      service {
        name         = "recipes"
        port         = "web"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      config {
        image = "${local.image}"
        ports = ["web"]

        sysctl = {
          "net.ipv4.ip_unprivileged_port_start" = "80"
        }

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/static:/opt/recipes/staticfiles",
          "${local.strg}/media:/opt/recipes/mediafiles"
        ]
      }
    }
  }
}
