locals {
  image = "docker.io/mirotalk/p2p@sha256:e83c31a3e45781d180e47452e1e9cc08ce73dc0b45269253cf795f91e044b010"
}

job "mirotalk" {
  group "mirotalk" {
    network {
      port "http" {
        to           = 3000
        host_network = "private"
      }
    }

    task "mirotalk" {
      driver = "podman"
      user   = "1000:1000"

      resources {
        memory_max = 1024
      }

      service {
        name         = "meet"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["public", "monitor:communication"]
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      template {
        data        = file("config.js")
        destination = "/local/config.js"
      }

      config {
        image = "${local.image}"
        ports = ["http"]

        force_pull = true

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "local/config.js:/src/app/src/config.js:ro"
        ]
      }
    }
  }
}
