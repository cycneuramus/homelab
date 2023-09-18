locals {
  strg = pathexpand("~/cld/emulatorjs")

  cloud_vol = {
    nes     = "emulatorjs_nes"
    snes    = "emulatorjs_snes"
    genesis = "emulatorjs_genesis"
    n64     = "emulatorjs_n64"
  }

  cleanup_args = concat(["volume", "rm"], values("${local.cloud_vol}"))
}

job "emulatorjs" {
  constraint {
    attribute = "${meta.performance}"
    value     = "high"
  }

  group "emulatorjs" {
    count = 1

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

    task "cleanup" {
      driver = "raw_exec"

      lifecycle {
        hook    = "poststop"
        sidecar = false
      }

      config {
        command = "docker"
        args    = "${local.cleanup_args}"
      }
    }

    task "emulatorjs" {
      driver = "docker"

      resources {
        memory_max = 2048
      }

      service {
        name     = "arcade"
        port     = "http"
        provider = "nomad"
        tags     = ["public"]
      }

      service {
        name     = "arcade-admin"
        port     = "admin"
        provider = "nomad"
        tags     = ["local"]
      }

      env {
        PUID = "1000"
        PGID = "1000"
        TZ   = "Europe/Stockholm"
      }

      config {
        image = "lscr.io/linuxserver/emulatorjs:latest"
        ports = ["http", "admin"]

        mount {
          type   = "bind"
          source = "${local.strg}/data"
          target = "/data"
        }

        mount {
          type   = "bind"
          source = "${local.strg}/config"
          target = "/config"
        }

        mount {
          type   = "volume"
          source = "${local.cloud_vol.nes}"
          target = "/data/nes/roms"
          volume_options {
            driver_config {
              name = "rclone"
              options {
                remote = "crypt:cld/emulatorjs/nes"
                uid    = "1000"
                gid    = "1000"
              }
            }
          }
        }

        mount {
          type   = "volume"
          source = "${local.cloud_vol.snes}"
          target = "/data/snes/roms"
          volume_options {
            driver_config {
              name = "rclone"
              options {
                remote = "crypt:cld/emulatorjs/snes"
                uid    = "1000"
                gid    = "1000"
              }
            }
          }
        }

        mount {
          type   = "volume"
          source = "${local.cloud_vol.genesis}"
          target = "/data/segaMD/roms"
          volume_options {
            driver_config {
              name = "rclone"
              options {
                remote = "crypt:cld/emulatorjs/genesis"
                uid    = "1000"
                gid    = "1000"
              }
            }
          }
        }

        mount {
          type   = "volume"
          source = "${local.cloud_vol.n64}"
          target = "/data/n64/roms"
          volume_options {
            driver_config {
              name = "rclone"
              options {
                remote = "crypt:cld/emulatorjs/n64"
                uid    = "1000"
                gid    = "1000"
              }
            }
          }
        }
      }
    }
  }
}
