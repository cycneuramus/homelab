locals {
  image = "quay.io/redlib/redlib@sha256:b945c6e15d27c93c9c89f331960838f2f20f2acae82a47f29afded67f508e920"
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
