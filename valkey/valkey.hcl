locals {
  strg  = "/mnt/nas/apps/valkey"
  image = "docker.io/valkey/valkey:9.0-alpine"
}

job "valkey" {
  group "valkey" {
    network {
      port "valkey" {
        to           = 6379
        host_network = "private"
      }
    }

    task "valkey" {
      driver = "podman"
      user   = "1000:1000"

      kill_timeout = "30s"

      resources {
        memory_max = 4096
      }

      service {
        name         = "valkey"
        port         = "valkey"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["private"]
      }

      config {
        image  = "${local.image}"
        ports  = ["valkey"]
        userns = "keep-id"

        command = "valkey-server"
        args = [
          "--save", "1800", "1", "600", "10",
          "--appendonly", "yes",
          "--appendfsync", "everysec",
          "--maxmemory-policy", "noeviction"
        ]

        logging {
          driver = "journald"
        }

        volumes = [
          "${local.strg}:/data"
        ]
      }
    }
  }
}
