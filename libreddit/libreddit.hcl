locals {
  image = "quay.io/redlib/redlib@sha256:fdfa1a6d4e14756c88085957ca0f89ce9bef6991cf3f6a4050f515ef1935e0ff"
}

job "libreddit" {
  group "libreddit" {
    network {
      port "http" {
        to           = 8080
        host_network = "private"
      }
    }

    task "libreddit" {
      driver = "podman"
      user   = "1000:1000"

      service {
        name         = "libreddit"
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
      }
    }
  }
}
