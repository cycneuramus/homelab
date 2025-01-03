locals {
  strg = "/mnt/jfs/renovate"
}

job "renovate" {
  type = "batch"

  periodic {
    crons            = ["0 5 * * 7"]
    prohibit_overlap = true
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
          rm ${local.strg}/renovate.log
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
        data        = file("config.js")
        destination = "/local/config.js"
      }

      config {
        image  = "ghcr.io/renovatebot/renovate:39.88.0"
        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = ["${local.strg}:/var/log/renovate"]
      }
    }
  }
}
