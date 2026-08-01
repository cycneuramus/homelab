locals {
  image = "docker.io/andrewsav/terraforming-mars@sha256:271d38796a1e5d9ca1b202db08e1b3de37f1f41662a01fbabe05fa6ddedccf0b"
  strg  = "..${NOMAD_ALLOC_DIR}/data"
}

job "terraforming-mars" {
  constraint {
    attribute = "${attr.cpu.arch}"
    operator  = "!="
    value     = "arm64"
  }

  group "terraforming-mars" {
    network {
      port "http" {
        to           = 8765
        host_network = "private"
      }
    }

    task "terraforming-mars" {
      driver = "podman"
      user   = "1000:1000"

      service {
        name         = "tm"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["public"]
      }

      env {
        NODE_ENV = "production"
        PORT     = "8765"
      }

      config {
        image = "${local.image}"
        ports = ["http"]

        force_pull = true

        volumes = [
          "${local.strg}:/usr/src/app/db"
        ]
      }
    }
  }
}
