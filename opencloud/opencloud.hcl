locals {
  strg = "/mnt/jfs/opencloud"
  data = "/mnt/nas/apps/opencloud"

  image = {
    opencloud = "docker.io/opencloudeu/opencloud-rolling:3.7.0"
    collabora = "docker.io/collabora/code:25.04.6.2.1"
  }
}

job "opencloud" {
  group "opencloud" {
    network {
      port "app" {
        to           = 9200
        host_network = "private"
      }

      port "wopi" {
        to           = 9300
        host_network = "private"
      }

      port "collabora" {
        to           = 9980
        host_network = "private"
      }
    }

    task "opencloud" {
      driver = "podman"
      user   = "1000:1000"

      resources {
        memory_max = 4096
      }

      service {
        name         = "opencloud"
        port         = "app"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      service {
        name         = "wopi"
        port         = "wopi"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      template {
        data        = file("app.env")
        destination = "env"
        env         = true
      }

      config {
        image = "${local.image.opencloud}"
        ports = ["app", "wopi"]

        entrypoint = ["/bin/sh", "-c", "opencloud init || true; opencloud server"]
        userns     = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/config:/etc/opencloud",
          "${local.data}:/var/lib/opencloud"
        ]
      }
    }

    task "wopi" {
      driver = "podman"
      user   = "1000:1000"

      lifecycle {
        hook    = "poststart"
        sidecar = true
      }

      template {
        data        = file("wopi.env")
        destination = "env"
        env         = true
      }

      config {
        image = "${local.image.opencloud}"

        network_mode = "task:opencloud"

        entrypoint = ["/bin/sh", "-c", "until nc -z 127.0.0.1 9142; do sleep 1; done; until nc -z $NOMAD_IP_collabora $NOMAD_HOST_PORT_collabora; do sleep 1; done; sleep 5; opencloud collaboration server"]
        userns     = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/config:/etc/opencloud",
        ]
      }
    }

    task "collabora" {
      driver = "podman"

      resources {
        memory_max = 4096
      }

      service {
        name         = "collabora"
        port         = "collabora"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      template {
        data        = file("collabora.env")
        destination = "env"
        env         = true
      }

      config {
        image = "${local.image.collabora}"
        ports = ["collabora"]

        entrypoint = ["/bin/bash", "-c", "coolconfig generate-proof-key && /start-collabora-online.sh"]

        logging = {
          driver = "journald"
        }
      }
    }
  }
}
