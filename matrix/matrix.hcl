locals {
  strg = "/mnt/jfs/matrix"
}

job "matrix" {
  group "matrix" {
    network {
      port "http" {
        to           = 6167
        host_network = "private"
      }

      port "signal-bridge" {
        to           = 29328
        host_network = "private"
      }
    }

    task "matrix" {
      driver = "podman"
      user   = "1000:1000"

      resources {
        memory_max = 1024
      }

      service {
        name         = "matrix"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      template {
        data        = file("config.toml")
        destination = "/local/config.toml"
      }

      env {
        CONDUWUIT_CONFIG = "/local/config.toml"
      }

      config {
        image = "ghcr.io/girlbossceo/conduwuit:main"
        ports = ["http"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/db:/var/lib/conduwuit"
        ]
      }
    }

    task "signal-bridge" {
      driver = "podman"

      service {
        name         = "signal-bridge"
        port         = "signal-bridge"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      env {
        UID = "0"
        GID = "0"
      }

      config {
        image = "dock.mau.dev/mautrix/signal:v0.7.4"
        ports = ["signal-bridge"]

        # userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/bridges/signal:/data"
        ]
      }
    }
  }
}
