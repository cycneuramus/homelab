locals {
  image = "docker.io/andrewsav/terraforming-mars@sha256:9f5a8314758c51bfe8676cc32d3c8a20c18d68e5752cf7e692848d2ad1f934d9"
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
