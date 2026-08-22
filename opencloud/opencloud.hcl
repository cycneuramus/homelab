locals {
  strg = "/mnt/jfs/opencloud"
  data = "/mnt/nas/apps/opencloud"

  image = {
    opencloud = "docker.io/opencloudeu/opencloud:7.2.4"
    collabora = "docker.io/collabora/code:26.04.3.1.1"
  }
}

job "opencloud" {
  group "opencloud" {
    network {
      port "app" {
        to           = 9200
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
        tags         = ["public"]
      }

      template {
        data        = file("app.env")
        destination = "env"
        env         = true
      }

      template {
        data        = <<-EOF
          #!/bin/sh
          collabora="http://${NOMAD_IP_collabora}:${NOMAD_HOST_PORT_collabora}/hosting/discovery"
          until curl -s "$collabora" -o /dev/null; do
            sleep 5
          done
          opencloud init || true; opencloud server
        EOF
        destination = "/local/entrypoint.sh"
        perms       = 755
      }

      config {
        image = "${local.image.opencloud}"
        ports = ["app"]

        entrypoint = ["/local/entrypoint.sh"]

        userns = "keep-id"

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
        tags         = ["public"]
      }

      template {
        data        = file("collabora.env")
        destination = "env"
        env         = true
      }

      config {
        image = "${local.image.collabora}"
        ports = ["collabora"]

        # entrypoint = ["/bin/bash", "-c", "coolconfig generate-proof-key && /start-collabora-online.sh"]
      }
    }
  }
}
