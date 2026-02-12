locals {
  strg  = "/mnt/jfs/signal-cli"
  image = "ghcr.io/asamk/signal-cli:0.13.24-native"
}

job "signal-cli-cron" {
  type = "batch"

  periodic {
    crons            = ["0 7 * * 7"]
    prohibit_overlap = true
  }

  group "signal-cli-cron" {
    task "signal-cli-cron" {
      driver = "podman"
      user   = "1000:1000"

      config {
        image = "${local.image}"
        args  = ["receive"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}:/var/lib/signal-cli"
        ]
      }
    }
  }
}
