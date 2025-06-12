locals {
  image = "ghcr.io/kanboard/kanboard:v1.2.45"
  strg  = "/mnt/jfs/kanboard"
}

job "kanboard" {
  group "kanboard" {
    network {
      port "http" {
        to           = 80
        host_network = "private"
      }
    }

    task "kanboard" {
      driver = "podman"
      # user   = "1000:1000"

      service {
        name         = "kanban"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      template {
        data        = file("entrypoint.sh")
        destination = "/local/entrypoint.sh"
        perms       = 755
      }

      config {
        image = "${local.image}"
        ports = ["http"]

        # userns = "keep-id"

        entrypoint = [
          "/local/entrypoint.sh"
        ]

        sysctl = {
          "net.ipv4.ip_unprivileged_port_start" = "80"
        }

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/data:/var/www/app/data",
          "${local.strg}/plugins:/var/www/app/plugins",
        ]
      }
    }
  }
}
