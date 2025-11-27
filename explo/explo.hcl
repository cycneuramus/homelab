locals {
  music = "/mnt/nas/apps/navidrome/discover/explo"
  image = "ghcr.io/lumepart/explo:v0.11.3"
}

job "explo" {
  group "explo" {
    task "explo" {
      driver = "podman"
      # user   = "1000:1000"

      template {
        data        = file(".env")
        destination = "local/env"
        env         = true
      }

      config {
        image = "${local.image}"

        # userns = "keep-id"

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
