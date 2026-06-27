locals {
  image = "ghcr.io/itxworks/imap-idle-notify@sha256:afe196103b50f1b1005669392b3fae9ee1df32f7cdf8e517eac87e7e0dfe9f9e"
}

job "imap-idle-notify" {
  group "imap-idle-notify" {
    task "imap-idle-notify" {
      driver = "podman"
      user   = "1000:1000"

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      config {
        image = "${local.image}"

        userns = "keep-id"

        logging = {
          driver = "journald"
        }
      }
    }
  }
}
