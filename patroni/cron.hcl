locals {
  strg  = "/mnt/nas/apps/patroni/apex"
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

      resources {
        memory_max = 2048
      }

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
  }
}
