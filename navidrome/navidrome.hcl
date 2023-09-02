locals {
  strg      = pathexpand("~/cld/navidrome")
  cloud_vol = "navidrome"
}

job "navidrome" {
  constraint {
    attribute = "${meta.performance}"
    value     = "high"
  }

  group "navidrome" {
    count = 1

    network {
      port "http" {
        to           = 4533
        host_network = "private"
      }
    }

    ephemeral_disk {
      migrate = true
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

    task "navidrome" {
      driver = "docker"
      user   = "1000:1000"

      resources {
        memory_max = 2048
      }

      service {
        name     = "navidrome"
        port     = "http"
        provider = "nomad"
        tags     = ["local", "monitor"]
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      config {
        image = "deluan/navidrome:latest"
        ports = ["http"]

        mount {
          type   = "bind"
          source = "local"
          target = "/data"
        }

        mount {
          type     = "volume"
          source   = "${local.cloud_vol}"
          target   = "/music"
          readonly = true
          volume_options {
            driver_config {
              name = "rclone"
              options {
                remote = "crypt:media/music"
                uid    = "1000"
                gid    = "1000"
              }
            }
          }
        }
      }
    }

    task "beets" {
      driver = "docker"

      env {
        PUID = "1000"
        PGID = "1000"
        TZ   = "Europe/Stockholm"
      }

      config {
        image = "lscr.io/linuxserver/beets:latest"

        mount {
          type   = "bind"
          source = "${local.strg}/config"
          target = "/config"
        }

        mount {
          type     = "volume"
          source   = "navidrome"
          target   = "/music"
          readonly = true
          volume_options {
            driver_config {
              name = "rclone"
              options {
                remote = "crypt:media/music"
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
