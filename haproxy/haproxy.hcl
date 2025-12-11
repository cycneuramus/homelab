locals {
  image = "docker.io/haproxy:3.3-alpine"
}

job "haproxy" {
  type = "system"

  group "haproxy" {
    network {
      port "patroni" {
        to           = 15432
        static       = 15432
        host_network = "private"
      }

      port "valkey" {
        to           = 16379
        static       = 16379
        host_network = "private"
      }

      port "garage" {
        to           = 13900
        static       = 13900
        host_network = "private"
      }

      port "stats" {
        to           = 7000
        host_network = "private"
      }
    }

    task "haproxy" {
      driver = "podman"

      service {
        name         = "haproxy-${attr.unique.hostname}"
        port         = "stats"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local", "monitor:network"]
      }

      template {
        data        = file("cfg-haproxy.cfg")
        destination = "local/haproxy.cfg"
      }

      config {
        image = "${local.image}"
        ports = ["patroni", "valkey", "garage", "stats"]

        logging = {
          driver = "journald"
        }

        entrypoint = [
          "haproxy", "-f", "/local/haproxy.cfg"
        ]
      }
    }
  }
}
