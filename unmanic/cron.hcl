job "cron-unmanic" {
  type = "batch"

  periodic {
    crons            = ["0 1 * * *"]
    prohibit_overlap = true
  }

  group "cron-unmanic" {
    task "cron-unmanic" {
      driver = "raw_exec"
      user   = "antsva"

      template {
        data        = <<-EOF
          #!/bin/sh
          {{ range nomadService "unmanic" }}
          curl -X 'POST' \
            'http://{{ .Address }}:{{ .Port }}/unmanic/api/v2/pending/rescan' \
            -H 'accept: application/json' \
            -d ''
          {{ end }}
        EOF
        destination = "local/entrypoint.sh"
        perms       = 755
      }

      config {
        command = "/local/entrypoint.sh"
      }
    }
  }
}
