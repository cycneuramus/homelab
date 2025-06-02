locals {
  image = "docker.io/lukevella/rallly:4.0"
}

job "rallly" {
  constraint {
    attribute = "${attr.cpu.arch}"
    operator  = "!="
    value     = "arm64"
  }

  group "rallly" {
    network {
      port "app" {
        to           = 3000
        host_network = "private"
      }
    }

    task "rallly" {
      driver = "podman"
      user   = "1000:1000"

      service {
        name         = "rallly"
        port         = "app"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["public"]
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      config {
        image = "${local.image}"
        ports = ["app"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }
      }
    }
  }
}
