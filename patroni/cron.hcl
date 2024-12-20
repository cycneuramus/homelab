locals {
  strg = pathexpand("~/.local/share/patroni")
}

job "patroni-cron" {
  type = "sysbatch"

  periodic {
    crons            = ["0 0 * * 7"]
    prohibit_overlap = true
  }

  constraint {
    attribute = "${attr.unique.hostname}"
    operator  = "set_contains_any"
    value     = "apex"
  }

  group "patroni-cron" {
    task "patroni-cron" {
      driver = "podman"
      user   = "1000:1000"

      template {
        data        = file("env_cron")
        destination = "env_cron"
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
        image      = "postgres:15-alpine"
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
          "crypt:cld/patroni/${attr.unique.hostname}",
          "--progress"
        ]
      }
    }

  }
}