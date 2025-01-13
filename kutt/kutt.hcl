locals {
  image = {
    kutt   = "docker.io/kutt/kutt:v3.0.3"
    valkey = "docker.io/valkey/valkey:8.0-alpine"
  }
}

job "kutt" {
  group "kutt" {
    network {
      port "app" {
        to           = 3000
        host_network = "private"
      }

      port "db" {
        to           = 5432
        host_network = "private"
      }

      port "redis" {
        to           = 6379
        host_network = "private"
      }
    }

    task "kutt" {
      driver = "podman"

      service {
        name         = "kutt"
        port         = "app"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["private"]
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      config {
        image = "${local.image.kutt}"
        ports = ["app"]

        logging = {
          driver = "journald"
        }
      }
    }

    task "redis" {
      driver = "podman"

      config {
        image = "${local.image.valkey}"
        ports = ["redis"]

        logging = {
          driver = "journald"
        }
      }
    }
  }
}
