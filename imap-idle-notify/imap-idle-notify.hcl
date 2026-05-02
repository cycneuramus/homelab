locals {
  image = "ghcr.io/itxworks/imap-idle-notify@sha256:3ce16b0c51944f46de1523217f48ad51e0e56397c36c4079650930dafcf3490e"
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
