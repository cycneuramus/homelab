job "flaresolverr" {
  group "flaresolverr" {
    network {
      port "http" {
        to           = 8191
        host_network = "private"
      }
    }

    task "flaresolverr" {
      driver = "podman"
      # user   = "1000:1000"

      service {
        name         = "flaresolverr"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      config {
        image = "ghcr.io/flaresolverr/flaresolverr:v3.3.21"
        ports = ["http"]

        logging = {
          driver = "journald"
        }
      }
    }
  }
}

