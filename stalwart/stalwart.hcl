locals {
  strg  = "/mnt/jfs/stalwart"
  image = "docker.io/stalwartlabs/stalwart:v0.12.5"
}

job "stalwart" {
  group "stalwart" {
    network {
      port "smtp" {
        to           = 25
        host_network = "private"
      }

      port "smtps" {
        to           = 465
        host_network = "private"
      }

      port "imaps" {
        to           = 993
        host_network = "private"
      }

      port "http" {
        to           = 8080
        host_network = "private"
      }
    }

    task "stalwart" {
      driver = "podman"
      user   = "1000:1000"

      resources {
        memory_max = 4096
      }

      service {
        name         = "smtp"
        port         = "smtp"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["private"]
      }

      service {
        name         = "smtps"
        port         = "smtps"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["private"]
      }

      service {
        name         = "imaps"
        port         = "imaps"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["private"]
      }

      service {
        name         = "stalwart"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      template {
        data        = file("config.toml")
        destination = "/local/config.toml"
        uid         = 1000
        gid         = 1000
      }

      config {
        image = "${local.image}"
        ports = ["smtp", "smtps", "imaps", "http"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        sysctl = {
          "net.ipv4.ip_unprivileged_port_start" = "25"
        }

        entrypoint = ["/usr/local/bin/stalwart", "--config", "/local/config.toml"]

        volumes = ["${local.strg}:/opt/stalwart"]
        tmpfs   = ["/var/log/tracer"]
      }
    }
  }
}
