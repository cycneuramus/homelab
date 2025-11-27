locals {
  strg  = "/mnt/jfs/ytdl-sub"
  media = "/mnt/nas/media/tv/yt"
  dl    = pathexpand("~/dl/ytdl-sub")

  image = "ghcr.io/jmbannon/ytdl-sub:2025.11.27"
}

job "ytdl-sub" {
  type = "batch"

  periodic {
    crons            = ["0 3 * * *"]
    prohibit_overlap = true
  }

  group "ytdl-sub" {
    task "ytdl-sub" {
      driver = "podman"

      resources {
        memory_max = 2048
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      template {
        data        = file("config.yaml")
        destination = "/local/config.yaml"
      }

      template {
        data        = file("subscriptions.yaml")
        destination = "/local/subscriptions.yaml"
      }

      template {
        data        = file("entrypoint.sh")
        destination = "/local/entrypoint.sh"
        perms       = 755
      }

      config {
        image = "${local.image}"

        entrypoint = [
          "/local/entrypoint.sh"
        ]

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.dl}:/dl",
          "${local.strg}:/logs",
          "${local.media}:/tv_shows",
        ]
      }
    }
  }
}
