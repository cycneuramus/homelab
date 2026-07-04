locals {
  image = "ghcr.io/itxworks/imap-idle-notify@sha256:0bae98e5bc9f2c701df5e17927f68dd90061d8d5b49b71aec7661107bac919a5"
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
