job "sysmonitor" {
  type = "system"

  group "sysmonitor" {
    task "sysmonitor" {
      driver = "raw_exec"
      user   = "antsva"

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

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
