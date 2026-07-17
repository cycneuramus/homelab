locals {
  image = "ghcr.io/itxworks/imap-idle-notify@sha256:9382cc82c3fc9edaf7f6ed1abb53d2dbd59bc96392884210a0d171ac166f8bff"
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
