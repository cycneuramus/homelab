locals {
  strg  = "/mnt/jfs/explo"
  music = "/mnt/nas/apps/navidrome/discover/explo"
  logs  = "..${NOMAD_ALLOC_DIR}/data"

  image = "ghcr.io/lumepart/explo:v1.1.2"
}

job "explo" {
  group "explo" {
    network {
      port "http" {
        to           = 7288
        host_network = "private"
      }
    }

    task "explo" {
      driver = "podman"

      resources {
        memory_max = 1024
      }

      service {
        name         = "explo"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      template {
        data        = file(".env")
        destination = "local/env"
        env         = true
      }

      config {
        image = "${local.image}"
        ports = ["http"]

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.music}:/data",
          "${local.strg}/cache:/opt/explo/config/cache",
          "${local.logs}:/opt/explo/config/logs",
          "local/env:/opt/explo/.env",
        ]
      }
    }
  }
}
