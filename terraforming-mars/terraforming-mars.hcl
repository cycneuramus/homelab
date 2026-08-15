locals {
  image = "docker.io/andrewsav/terraforming-mars@sha256:f8871ca5d926d9ad194d5fde2e6c5decf20baac4b58265725b3227192fc30440"
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
