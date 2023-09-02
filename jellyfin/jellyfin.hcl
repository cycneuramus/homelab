locals {
  strg = pathexpand("~/cld/jellyfin")
  cloud_vol = "jellyfin"
}

job "jellyfin" {
  constraint {
    attribute = "${attr.unique.hostname}"
    value     = "apex"
  }

  constraint {
    attribute = "${attr.unique.hostname}"
    operator  = "set_contains_any"
    value     = "apex,home,vps"
  }

  affinity {
    attribute = "${attr.unique.hostname}"
    value     = "apex"
    weight    = 100
  }

  affinity {
    attribute = "${attr.unique.hostname}"
    value     = "home"
    weight    = 25
  }

  group "jellyfin" {
    count = 1

    network {
      port "http" {
        to           = 8096
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

    task "jellyfin" {
      driver = "docker"

      resources {
        memory_max = 8192
      }

      service {
        name     = "jellyfin"
        port     = "http"
        provider = "nomad"
        tags     = ["public", "monitor"]
      }

      env {
        PUID = "1000"
        PGID = "1000"
        TZ   = "Europe/Stockholm"
      }

      template {
        source      = "${local.strg}/encoding.xml.tpl"
        destination = "encoding.xml"
      }

      config {
        image = "lscr.io/linuxserver/jellyfin"
        ports = ["http"]

        mount {
          type   = "bind"
          source = "${local.strg}/config"
          target = "/config"
        }

        mount {
          type   = "bind"
          source = "encoding.xml"
          target = "/config/encoding.xml"
        }

        mount {
          type   = "volume"
          source = "${local.cloud_vol}"
          target = "/mnt/cryptnas/media"
          volume_options {
            driver_config {
              name = "rclone"
              options {
                remote = "jellyfin:media"
                uid    = "1000"
                gid    = "1000"
              }
            }
          }
        }

        devices = [
          {
            host_path = "/dev/dri"
          }
        ]
      }
    }
  }
}
