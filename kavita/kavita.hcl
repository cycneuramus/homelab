locals {
  strg      = pathexpand("~/cld/kavita")
  cloud_vol = "kavita"
}

job "kavita" {
  constraint {
    attribute = "${meta.performance}"
    value     = "high"
  }

  group "kavita" {
    count = 1

    network {
      port "http" {
        to           = 5000
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

    task "kavita" {
      driver = "docker"

      service {
        name     = "kavita"
        port     = "http"
        provider = "nomad"
        tags     = ["local"]
      }

      config {
        image = "kizaing/kavita:latest"
        ports = ["http"]

        mount {
          type   = "bind"
          source = "${local.strg}/config"
          target = "/kavita/config"
        }

        mount {
          type     = "volume"
          source   = "${local.cloud_vol}"
          target   = "/books"
          readonly = true
          volume_options {
            driver_config {
              name = "rclone"
              options {
                remote = "crypt:cld/nextcloud/user-1/files/Texter"
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
