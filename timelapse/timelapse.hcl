locals {
  strg  = "/mnt/jfs/timelapse"
  image = "docker.io/arnaudcayrol/immich-selfie-timelapse:2.1.1"
}

job "timelapse" {
  affinity {
    attribute = "${attr.unique.hostname}"
    value     = "horreum"
    weight    = -50
  }

  group "timelapse" {
    network {
      port "http" {
        to           = 5000
        host_network = "private"
      }
    }

    task "timelapse" {
      driver = "podman"
      user   = "1000:1000"

      resources {
        memory_max = 8192
      }

      service {
        name         = "timelapse"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local", "monitor:personal"]
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      config {
        image = "${local.image}"
        ports = ["http"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/config:/app/config",
          "${local.strg}/output:/app/output"
        ]
      }
    }
  }
}
