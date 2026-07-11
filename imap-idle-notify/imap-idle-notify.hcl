locals {
  image = "ghcr.io/itxworks/imap-idle-notify@sha256:c84b84cb10010a5532c48c1f0044e8b675396b084b09d90a3e76ddd631c2851a"
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
