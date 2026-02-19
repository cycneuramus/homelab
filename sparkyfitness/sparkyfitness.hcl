locals {
  image = {
    backend  = "ghcr.io/codewithcj/sparkyfitness-server:v0.16.4.4"
    frontend = "ghcr.io/codewithcj/sparkyfitness-frontend:v0.16.4.4"
  }
}

job "sparkyfitness" {
  group "sparkyfitness" {
    network {
      port "http" {
        to           = 80
        host_network = "private"
      }
    }

    task "backend" {
      driver = "podman"
      # user   = "1000:1000"

      service {
        name         = "fitness"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local", "monitor:personal"]
      }

      template {
        data        = file("backend.env")
        destination = "env"
        env         = true
      }

      config {
        image = "${local.image.backend}"
        ports = ["http"]

        # userns = "keep-id"

        logging = {
          driver = "journald"
        }
      }
    }

    task "frontend" {
      driver = "podman"
      # user   = "1000:1000"

      lifecycle {
        hook    = "poststart"
        sidecar = true
      }

      template {
        data        = file("frontend.env")
        destination = "env"
        env         = true
      }

      config {
        image = "${local.image.frontend}"

        network_mode = "task:backend"

        # userns = "keep-id"

        logging = {
          driver = "journald"
        }
      }
    }

  }
}
