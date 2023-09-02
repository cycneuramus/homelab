locals {
  cloud_vol = "audiobooks"
  strg      = pathexpand("~/cld/audiobookshelf")
}

job "audiobookshelf" {
  constraint {
    attribute = "${meta.performance}"
    value     = "high"
  }

  constraint {
    attribute = "${attr.cpu.arch}"
    operator  = "!="
    value     = "arm64"
  }

  group "audiobookshelf" {
    count = 1

    network {
      port "http" {
        to           = 80
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
        args    = ["volume", "rm", "${local.cloud_vol}"]
      }
    }

    task "audiobookshelf" {
      driver = "docker"
      user   = "1000:1000"

      resources {
        memory_max = 2048
      }

      service {
        name     = "audiobooks"
        port     = "http"
        provider = "nomad"
        tags     = ["public", "monitor"]
      }

      config {
        image = "ghcr.io/advplyr/audiobookshelf:latest"
        ports = ["http"]

        mount {
          type   = "bind"
          source = "${local.strg}/data/config"
          target = "/config"
        }

        mount {
          type   = "bind"
          source = "${local.strg}/data/metadata"
          target = "/metadata"
        }

        mount {
          type     = "volume"
          source   = "${local.cloud_vol}"
          target   = "/audiobooks/kids"
          readonly = false
          volume_options {
            driver_config {
              name = "rclone"
              options {
                remote = "crypt:cld/audiobookshelf"
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
