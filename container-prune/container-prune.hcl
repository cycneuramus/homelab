job "container-prune" {
  type = "sysbatch"

  periodic {
    crons            = ["0 1 * * 7"]
    prohibit_overlap = true
  }

  group "container-prune" {
    task "container-prune" {
      driver = "raw_exec"

      template {
        data        = file("entrypoint.sh")
        destination = "local/entrypoint.sh"
        perms       = 755
      }

      config {
        command = "/local/entrypoint.sh"
      }
    }
  }
}
