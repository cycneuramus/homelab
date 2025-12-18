locals {
  strg = "/mnt/jfs/opencloud"
  data = "/mnt/nas/apps/opencloud"

  image = {
    opencloud = "docker.io/opencloudeu/opencloud-rolling:4.1.0"
    collabora = "docker.io/collabora/code:25.04.8.1.1"
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
        tags         = ["local", "monitor:collaboration"]
      }

      # WOPI service goes here since the wopi task attaches to this task's network
      service {
        name         = "wopi"
        port         = "wopi"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local", "monitor:collaboration"]
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
          "${local.strg}/idm:/var/lib/opencloud/idm",
          "${local.strg}/idp:/var/lib/opencloud/idp",
          "${local.strg}/nats:/var/lib/opencloud/nats",
          "${local.strg}/search:/var/lib/opencloud/search",
          "${local.data}/thumbnails:/var/lib/opencloud/thumbnails",
          "${local.data}/storage:/var/lib/opencloud/storage"
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

      template {
        data        = <<-EOF
          #!/bin/sh
          collabora="http://${NOMAD_IP_collabora}:${NOMAD_HOST_PORT_collabora}/hosting/discovery"
          until nc -z 127.0.0.1 9142 && curl -s "$collabora" -o /dev/null; do
            sleep 5
          done
          opencloud collaboration server
        EOF
        destination = "/local/entrypoint.sh"
        perms       = 755
      }

      config {
        image = "${local.image.opencloud}"

        network_mode = "task:opencloud"

        entrypoint = ["/local/entrypoint.sh"]
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
        tags         = ["local", "monitor:collaboration"]
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
