locals {
  nas   = "/mnt/nas/apps"
  image = "ghcr.io/cycneuramus/ifexifextract:latest"
}

job "gollery" {
  type = "batch"

  periodic {
    crons            = ["@daily"]
    prohibit_overlap = true
  }

  group "gollery" {
    task "mnt-refresh" {
      driver = "raw_exec"
      user   = "antsva"

      lifecycle {
        hook    = "prestart"
        sidecar = false
      }

      template {
        data        = <<-EOF
          #!/bin/bash
          rclone rc vfs/refresh dir=gollery recursive=true --rc-addr 127.0.0.1:5575
        EOF
        destination = "local/mnt-refresh.sh"
        perms       = 755
      }

      config {
        command = "local/mnt-refresh.sh"
      }
    }


    task "extractor" {
      driver = "podman"
      user   = "1000:1000"

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      config {
        image   = "${local.image}"
        command = "extract"

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.nas}/nextcloud/antsva/files/Bilder:/home/extractor/src",
          "${local.nas}/gollery:/home/extractor/data"
        ]
      }
    }
  }
}
