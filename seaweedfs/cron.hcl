locals {
  masters = "10.10.10.10:9333,10.10.10.11:9333,10.10.10.12:9333"
}

job "seaweedfs-cron" {
  type = "batch"

  periodic {
    cron             = "0 3 * * *"
    prohibit_overlap = true
  }

  group "seaweedfs-cron" {
    count = 1

    task "seaweedfs-cron" {
      driver = "docker"
      user   = "1000:1000"

      env {
        SHELL_MASTER = "${local.masters}"
      }

      config {
        image = "chrislusf/seaweedfs:latest"
        args = [
          "shell",
          "lock;",
          "volume.check.disk -force;",
          "volume.deleteEmpty -quietFor=24h -force;",
          "volume.fsck;",
          "unlock"
        ]
      }
    }
  }
}
