job "renovate" {
  type = "batch"

  periodic {
    crons            = ["0 5 * * 7"]
    prohibit_overlap = true
  }

  group "renovate" {
    task "renovate" {
      driver = "podman"
      user   = "1000:1000"

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      template {
        data        = file("config.js")
        destination = "/local/config.js"
      }

      config {
        image  = "ghcr.io/renovatebot/renovate:39.88.0"
        userns = "keep-id"

        logging = {
          driver = "journald"
        }
      }
    }
  }
}
