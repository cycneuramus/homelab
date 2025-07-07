locals {
  strg  = "/mnt/jfs/rustical"
  image = "ghcr.io/lennart-k/rustical:0.4.11"
}

job "rustical" {
  group "rustical" {
    network {
      port "http" {
        to           = 4000
        host_network = "private"
      }
    }

    task "rustical" {
      driver = "podman"
      user   = "1000:1000"

      service {
        name         = "dav"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      template {
        data        = file("config.toml")
        destination = "/local/config.toml"
      }

      config {
        image = "${local.image}"
        ports = ["http"]

        userns = "keep-id"

        entrypoint = [
          "rustical", "-c", "/local/config.toml"
        ]

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}:/var/lib/rustical"
        ]
      }
    }
  }
}
