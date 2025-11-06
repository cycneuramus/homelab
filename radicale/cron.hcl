locals {
  strg = "/mnt/jfs/radicale/vcf-to-ics"
}

job "cron-radicale" {
  type = "batch"

  periodic {
    crons            = ["30 5 * * *"]
    prohibit_overlap = true
  }

  group "cron-radicale" {
    task "cron-radicale" {
      driver = "raw_exec"
      user   = "antsva"

      config {
        command = "sh"
        args = [
          "${local.strg}/birthdays.sh"
        ]
      }
    }
  }
}
