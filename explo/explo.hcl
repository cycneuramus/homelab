locals {
  music = "/mnt/nas/apps/navidrome/discover/explo"
  image = "ghcr.io/lumepart/explo:v0.11.5"
}

job "explo" {
  group "explo" {
    task "explo" {
      driver = "podman"

      resources {
        memory_max = 1024
      }

      template {
        data        = file(".env")
        destination = "local/env"
        env         = true
      }

      config {
        image = "${local.image}"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.music}:/data",
          "local/env:/opt/explo/.env",
        ]
      }
    }
  }
}
