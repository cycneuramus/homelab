locals {
  strg  = "/mnt/jfs/renovate"
  image = "ghcr.io/renovatebot/renovate:42"
}

job "renovate" {
  type = "batch"

  periodic {
    crons            = ["0 9 * * 4"]
    prohibit_overlap = true
    time_zone        = "Europe/Stockholm"
  }

  group "renovate" {
    task "preflight" {
      driver = "raw_exec"
      user   = "antsva"

      lifecycle {
        hook    = "prestart"
        sidecar = false
      }

      template {
        data        = <<-EOF
          #!/bin/bash
          : > ${local.strg}/renovate.log
        EOF
        destination = "local/preflight.sh"
        perms       = 755
      }

      config {
        command = "local/preflight.sh"
      }
    }

    task "renovate" {
      driver = "podman"
      user   = "1000:1000"

      resources {
        memory_max = 1024
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      template {
        data            = file("config.js")
        destination     = "/local/config.js"
        left_delimiter  = "[["
        right_delimiter = "]]"
      }

      config {
        image  = "${local.image}"
        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}:/var/log/renovate"
        ]
      }
    }
  }
}
