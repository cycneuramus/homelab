locals {
  music = "/mnt/nas/apps/music/explo"
  image = "ghcr.io/lumepart/explo:v0.10.2"
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
