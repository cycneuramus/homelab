locals {
  strg      = "/mnt/jfs/stump"
  nas       = "/mnt/nas/apps"
  user1path = split("=", chomp(file("user1path.env")))[1]
  user2path = split("=", chomp(file("user2path.env")))[1]

  image = "docker.io/aaronleopold/stump:0.0.11"
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

      resources {
        memory_max = 1024
      }

      service {
        name         = "books"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      env {
        STUMP_ENABLE_UPLOAD = true
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
          "${local.nas}/${local.user1path}:/user1:ro",
          "${local.nas}/${local.user2path}:/user2"
        ]
      }
    }
  }
}
