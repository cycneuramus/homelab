locals {
  strg = "/mnt/jfs/matrix"

  image = {
    matrix          = "ghcr.io/matrix-construct/tuwunel@sha256:fb3bb6876367d591ed7b50aedd654bd203e261bff89a5f1aaee83f3edddc0a93"
    signal-bridge   = "dock.mau.dev/mautrix/signal:v0.8.4"
    whatsapp-bridge = "dock.mau.dev/mautrix/whatsapp:v0.12.2"
  }
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

      port "whatsapp-bridge" {
        to           = 29318
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
        tags         = ["public"]
      }

      template {
        data        = file("config.toml")
        destination = "/local/config.toml"
      }

      env {
        TUWUNEL_CONFIG = "/local/config.toml"
      }

      config {
        image = "${local.image.matrix}"
        ports = ["http"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/db:/var/lib/tuwunel"
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
        image = "${local.image.signal-bridge}"
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

    task "whatsapp-bridge" {
      driver = "podman"

      service {
        name         = "whatsapp-bridge"
        port         = "whatsapp-bridge"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      env {
        UID = "0"
        GID = "0"
      }

      config {
        image = "${local.image.whatsapp-bridge}"
        ports = ["whatsapp-bridge"]

        # userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/bridges/whatsapp:/data"
        ]
      }
    }
  }
}
