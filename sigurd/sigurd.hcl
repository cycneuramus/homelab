locals {
  strg = "/mnt/jfs/sigurd"

  image = {
    sigurd     = "ghcr.io/cycneuramus/sigurd:latest"
    signal-api = "docker.io/bbernhard/signal-cli-rest-api:0.90"
  }
}

job "sigurd" {
  constraint {
    attribute = "${attr.cpu.arch}"
    operator  = "!="
    value     = "arm64"
  }

  group "sigurd" {
    network {
      port "signal-api" {
        to           = 8080
        host_network = "private"
      }
    }

    task "signal-api" {
      driver = "podman"
      user   = "0:0"

      service {
        name         = "signal-api"
        port         = "signal-api"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["private"]
      }

      env {
        MODE                  = "json-rpc"
        SIGNAL_CLI_CONFIG_DIR = "/signal-cli"
        SIGNAL_CLI_GID        = "1000"
        SIGNAL_CLI_UID        = "1000"
      }

      template {
        data        = file("signal-api-entrypoint.sh")
        destination = "/local/entrypoint.sh"
        perms       = 755
      }

      config {
        image = "${local.image.signal-api}"
        ports = ["signal-api"]

        userns = "keep-id"

        entrypoint = [
          "/local/entrypoint.sh"
        ]

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/music:/music",
          "${local.strg}/bot:/home/sigurd/bot",
          "${local.strg}/signal-cli-rest-api:/signal-cli", # watch out for silent permissions issues here
        ]
      }
    }

    task "bot" {
      driver = "podman"
      user   = "1000:1000"

      resources {
        memory_max = 8192
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      config {
        image   = "${local.image.sigurd}"
        command = "bot"

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/music:/music",
          "${local.strg}/bot:/home/sigurd/bot",
          # "${local.strg}/signald:/signald",
        ]
      }
    }

    task "cron" {
      driver = "podman"
      user   = "1000:1000"

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      config {
        image   = "${local.image.sigurd}"
        command = "cron"

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/bot:/home/sigurd/bot",
        ]
      }
    }
  }
}
