locals {
  strg     = "/mnt/jfs/stump"
  crypt    = "/mnt/crypt"
  bookpath = split("=", chomp(file("bookpath.env")))[1]

  image = "docker.io/aaronleopold/stump:0.0.10"
}

job "stump" {
  group "stump" {
    network {
      port "http" {
        to           = 10801
        host_network = "private"
      }
    }

    task "stump" {
      driver = "podman"
      user   = "0:0"

      service {
        name         = "books"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      config {
        image = "${local.image}"
        ports = ["http"]

        # userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}:/config",
          "${local.crypt}/${local.bookpath}:/data:ro"
        ]
      }
    }
  }
}
