locals {
  strg = "/mnt/jfs/emulatorjs"
}

job "emulatorjs" {
  group "emulatorjs" {
    network {
      port "http" {
        to           = 80
        host_network = "private"
      }

      port "admin" {
        to           = 3000
        host_network = "private"
      }
    }

    task "emulatorjs" {
      driver = "podman"
      user   = "0:0"

      resources {
        memory_max = 2048
      }

      service {
        name         = "arcade"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["public"]
      }

      service {
        name         = "arcade-admin"
        port         = "admin"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      env {
        PUID         = "1000"
        PGID         = "1000"
        TZ           = "Europe/Stockholm"
        DISABLE_IPFS = true
      }

      config {
        image = "ghcr.io/linuxserver/emulatorjs:1.9.2"
        ports = ["http", "admin"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/config:/config",
          "${local.strg}/data:/data",
          "${local.strg}/roms/nes:/data/nes/roms",
          "${local.strg}/roms/snes:/data/snes/roms",
          "${local.strg}/roms/genesis:/data/segaMD/roms",
          "${local.strg}/roms/n64:/data/n64/roms"
        ]
      }
    }
  }
}
