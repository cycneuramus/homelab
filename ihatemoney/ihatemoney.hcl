locals {
  image = "docker.io/ihatemoney/ihatemoney:6.1.5"
}

job "ihatemoney" {
  group "ihatemoney" {
    network {
      port "http" {
        to           = 8000
        host_network = "private"
      }
    }

    task "ihatemoney" {
      driver = "podman"
      # user   = "1000:1000"

      service {
        name         = "ihatemoney"
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

        # userns = "keep-id"

        logging = {
          driver = "journald"
        }
      }
    }
  }
}
