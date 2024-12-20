job "container-prune" {
  type = "sysbatch"

  periodic {
    crons            = ["0 1 * * 7"]
    prohibit_overlap = true
  }

  group "container-prune" {
    task "container-prune" {
      driver = "raw_exec"
      user   = "antsva"

      config {
        command = "podman"
        args = [
          "system",
          "prune",
          "--volumes",
          "--force"
        ]
      }
    }
  }
}
