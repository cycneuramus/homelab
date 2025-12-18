locals {
  image = "ghcr.io/iamspido/github-release-monitor:1.4.1"
  strg  = "/mnt/jfs/ghrm"
}

job "ghrm" {
  group "ghrm" {
    network {
      port "app" {
        to           = 3000
        host_network = "private"
      }
    }

    task "ghrm" {
      driver = "podman"
      user   = "1000:1000"

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      service {
        name         = "ghrm"
        port         = "app"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local", "monitor:monitoring"]
      }

      config {
        image = "${local.image}"
        ports = ["app"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}:/app/data"
        ]
      }
    }
  }
}
