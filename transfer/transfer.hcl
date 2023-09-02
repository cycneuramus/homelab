locals {
  cloud_vol = "transfer"
  strg      = pathexpand("~/cld/transfer")
}

job "transfer" {
  constraint {
    attribute = "${meta.performance}"
    value     = "high"
  }

  group "transfer" {
    count = 1

    network {
      port "http" {
        to           = 8080
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

    task "transfer" {
      driver = "docker"
      user   = "1000:1000"

      service {
        name     = "transfer"
        port     = "http"
        provider = "nomad"
        tags     = ["private", "monitor"]
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      config {
        image = "dutchcoders/transfer.sh:latest"
        ports = ["http"]

        mount {
          type     = "volume"
          source   = "${local.cloud_vol}"
          target   = "/data"
          readonly = true
          volume_options {
            driver_config {
              name = "rclone"
              options {
                remote = "crypt:cld/transfer"
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
