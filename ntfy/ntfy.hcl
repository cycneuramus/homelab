locals {
  image = "docker.io/binwiederhier/ntfy:v2.16.0"
}

job "ntfy" {
  group "ntfy" {
    network {
      port "http" {
        to           = 8080
        host_network = "private"
      }
    }

    task "ntfy" {
      driver = "podman"
      user   = "1000:1000"

      service {
        name         = "ntfy"
        port         = "http"
        address_mode = "host"
        provider     = "nomad"
        tags         = ["public", "monitor:communication"]
      }

      template {
        data        = file("server.yml")
        destination = "/local/server.yml"
        uid         = 1000
        gid         = 1000
      }

      env {
        TZ = "Europe/Stockholm"
      }

      config {
        image = "${local.image}"
        ports = ["http"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        command = "serve"
        args    = ["-c", "/local/server.yml"]

        tmpfs = ["/var/cache/ntfy"]
      }
    }
  }
}
