locals {
  strg = pathexpand("~/.local/share/beszel")

  image = {
    hub   = "ghcr.io/henrygd/beszel/beszel:0.17.0"
    agent = "ghcr.io/henrygd/beszel/beszel-agent:0.17.0-alpine"
  }
}

job "beszel" {
  group "hub" {
    constraint {
      attribute = "${attr.unique.hostname}"
      value     = "apex"
    }

    network {
      port "http" {
        to           = 8090
        host_network = "private"
      }
    }

    task "beszel" {
      driver = "podman"
      user   = "1000:1000"

      service {
        name         = "beszel"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local", "monitor:monitoring"]
      }

      template {
        data        = file("hub.env")
        destination = "env"
        env         = true
      }

      config {
        image = "${local.image.hub}"
        ports = ["http"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}:/beszel_data"
        ]
      }
    }
  }

  group "agent" {
    count = 3

    constraint {
      distinct_hosts = true
    }

    network {
      port "http" {
        static       = 45876
        host_network = "private"
      }
    }

    task "beszel" {
      driver = "podman"
      # user   = "1000:1000"

      template {
        data        = file("agent.env")
        destination = "env"
        env         = true
      }

      config {
        image = "${local.image.agent}"
        ports = ["http"]

        socket     = "root"
        privileged = true

        network_mode = "host"

        # userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "/dev:/dev:ro",
          "/var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket:ro",
          "/run/user/1000/podman/podman.sock:/run/user/1000/podman/podman.sock:ro",
          "/mnt/jfs/.beszel:/extra-filesystems/jfs:ro",
          "/mnt/nas/.beszel:/extra-filesystems/nas:ro",
        ]
      }
    }
  }
}
