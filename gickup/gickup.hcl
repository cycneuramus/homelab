locals {
  image = "ghcr.io/cooperspencer/gickup:0.10.36"
}

job "gickup" {
  group "gickup" {
    task "gickup" {
      driver = "podman"
      user   = "1000:1000"

      template {
        data        = file("config.yml")
        destination = "/local/config.yml"
      }

      config {
        image   = "${local.image}"
        command = "/local/config.yml"

        userns = "keep-id"

        logging = {
          driver = "journald"
        }
      }
    }
  }
}
