locals {
  strg  = pathexpand("~/.local/share/patroni")
  nas   = "/mnt/nas/apps"
  image = "docker.io/postgres:17-alpine"
}

job "cron-patroni" {
  type = "sysbatch"

  periodic {
    crons            = ["30 4 * * *"]
    prohibit_overlap = true
  }

  constraint {
    attribute = "${attr.unique.hostname}"
    operator  = "set_contains_any"
    value     = "apex"
  }

  group "cron-patroni" {
    task "cron-patroni" {
      driver = "podman"
      user   = "1000:1000"

      template {
        data        = file(".env-cron")
        destination = ".env-cron"
        env         = true
      }

      template {
        data        = <<-EOF
          #!/bin/sh

          pg_dumpall \
            -v \
            -w \
            -h {{ env "attr.unique.network.ip-address" }} \
            -p 15432 \
            -U postgres \
            -f /patroni/backup.sql
        EOF
        destination = "local/pg_backup.sh"
        perms       = 755
      }

      config {
        image      = "${local.image}"
        entrypoint = ["/local/pg_backup.sh"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}:/patroni"
        ]
      }
    }

    task "offsite" {
      driver = "raw_exec"
      user   = "antsva"

      lifecycle {
        hook    = "poststop"
        sidecar = false
      }

      config {
        command = "rclone"
        args = [
          "copy",
          "${local.strg}/backup.sql",
          "${local.nas}/patroni/${attr.unique.hostname}",
          "--progress"
        ]
      }
    }
  }
}
