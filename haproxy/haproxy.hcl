job "haproxy" {
  type = "system"

  group "haproxy" {
    network {
      port "patroni" {
        to           = 15432
        static       = 15432
        host_network = "private"
      }

      port "s3" {
        to           = 18333
        static       = 18333
        host_network = "private"
      }

      port "stats" {
        to           = 7000
        host_network = "private"
      }
    }

    task "haproxy" {
      driver = "docker"

      service {
        name     = "haproxy"
        port     = "stats"
        provider = "nomad"
        tags     = ["local", "multi"]
      }

      template {
        data        = file("cfg-haproxy.cfg")
        destination = "local/haproxy.cfg"
      }

      config {
        image = "haproxy:lts-alpine"
        ports = ["patroni", "s3", "stats"]

        entrypoint = [
          "haproxy", "-f", "/local/haproxy.cfg"
        ]
      }
    }
  }
}
