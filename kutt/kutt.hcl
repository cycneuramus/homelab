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

    task "app" {
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
        image = "kutt/kutt:v2.7.4"
        ports = ["app"]

        logging = {
          driver = "journald"
        }

        command = "./wait-for-it.sh"
        args    = ["${attr.unique.network.ip-address}:15432", "--", "npm", "start"]
      }
    }

    task "redis" {
      driver = "podman"

      config {
        image = "valkey/valkey:8.0-alpine"
        ports = ["redis"]

        logging = {
          driver = "journald"
        }
      }
    }
  }
}
