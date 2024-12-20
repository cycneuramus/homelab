locals {
  strg = "/mnt/jfs/sigurd"
  version = {
    signal-cli-rest-api = "0.89"
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
      port "signal-cli-rest-api" {
        to           = 8080
        host_network = "private"
      }
    }

    task "signal-cli-rest-api" {
      driver = "podman"

      lifecycle {
        hook    = "prestart"
        sidecar = true
      }

      service {
        name         = "signal-cli-rest-api"
        port         = "signal-cli-rest-api"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["private"]
      }

      env {
        MODE           = "json-rpc"
        SIGNAL_CLI_UID = 1000
        SIGNAL_CLI_GID = 1000
      }

      config {
        image = "docker.io/bbernhard/signal-cli-rest-api:${local.version.signal-cli-rest-api}"
        ports = ["signal-cli-rest-api"]

        socket = "root"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/music:/music",
          "${local.strg}/bot:/home/sigurd/bot",
          "${local.strg}/signal-cli-rest-api:/home/.local/share/signal-cli",
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
        image   = "ghcr.io/cycneuramus/sigurd:latest"
        command = "bot"

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/music:/music",
          "${local.strg}/bot:/home/sigurd/bot",
          "${local.strg}/signald:/signald",
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
        image   = "ghcr.io/cycneuramus/sigurd"
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
