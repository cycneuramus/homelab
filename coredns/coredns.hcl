locals {
  image = "docker.io/coredns/coredns:1.13.2"
}

job "coredns" {
  type = "service"

  group "coredns" {
    count = 3

    constraint {
      attribute = "${meta.ingress}"
      value     = "true"
    }

    constraint {
      distinct_hosts = true
    }

    network {
      port "dns" {
        to           = 1053
        static       = 1053
        host_network = "private"
      }
    }

    task "coredns" {
      driver = "podman"
      user   = "1000:1000"

      config {
        image = "${local.image}"
        ports = ["dns"]

        args = ["-conf", "/local/Corefile", "-dns.port", "1053"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }
      }

      service {
        name         = "coredns-${attr.unique.hostname}"
        provider     = "nomad"
        port         = "dns"
        address_mode = "host"
        tags         = ["local", "monitor:network"]
      }

      template {
        data          = file("Corefile.tpl")
        destination   = "/local/Corefile"
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }
    }
  }
}
