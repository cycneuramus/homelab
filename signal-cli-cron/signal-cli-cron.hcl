locals {
  strg = "/mnt/jfs/signal-cli"
}

job "signal-cli-cron" {
  type = "batch"

  periodic {
    crons            = ["0 8 * * 7"]
    prohibit_overlap = true
  }

  group "signal-cli-cron" {
    task "signal-cli-cron" {
      driver = "podman"
      user   = "1000:1000"

      config {
        image = "ghcr.io/asamk/signal-cli:latest-native"
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
