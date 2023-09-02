locals {
  strg      = pathexpand("~/cld/ytdl-sub")
  dl        = pathexpand("~/dl")
  cloud_vol = "ytdl_sub"

}

job "ytdl-sub" {
  constraint {
    attribute = "${meta.performance}"
    value     = "high"
  }

  group "ytdl-sub" {
    count = 1

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

    task "ytdl-sub" {
      driver = "docker"

      env {
        PUID        = "1000"
        PGID        = "1000"
        TZ          = "Europe/Stockholm"
        DOCKER_MODS = "linuxserver/mods:universal-cron"
      }

      config {
        image = "ghcr.io/jmbannon/ytdl-sub:latest"

        mount {
          type   = "bind"
          source = "${local.strg}/config"
          target = "/config"
        }

        mount {
          type   = "bind"
          source = "${local.dl}"
          target = "/dl"
        }

        mount {
          type   = "volume"
          source = "${local.cloud_vol}"
          target = "/tv_shows"
          volume_options {
            driver_config {
              name = "rclone"
              options {
                remote = "jellyfin:media/tv/yt"
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
