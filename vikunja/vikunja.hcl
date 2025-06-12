locals {
  image = "docker.io/vikunja/vikunja:0.24.6"
  strg  = "/mnt/jfs/vikunja"
}

job "vikunja" {
  group "vikunja" {
    network {
      port "http" {
        to           = 3456
        host_network = "private"
      }
    }

    task "vikunja" {
      driver = "podman"
      user   = "1000:1000"

      service {
        name         = "vikunja"
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

      config {
        image = "${local.image}"
        ports = ["http"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}:/app/vikunja/files"
        ]
      }
    }
  }
}
