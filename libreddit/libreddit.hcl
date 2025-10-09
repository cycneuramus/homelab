locals {
  image = "quay.io/redlib/redlib@sha256:25dbb5466ebd22e58277d4aa54897899b044f02f7219ca3054784aecc0be34e1"
  # image = "git.ptr.moe/baalajimaestro/redlib@sha256:c882cf38b61063a497e494cac0f0ddeee2a9f6e09411d6b8c4afe5e46c1d0e7a"
}

job "libreddit" {
  group "libreddit" {
    network {
      port "http" {
        to           = 8080
        host_network = "private"
      }
    }

    task "libreddit" {
      driver = "podman"
      user   = "1000:1000"

      service {
        name         = "libreddit"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      config {
        image = "${local.image}"
        ports = ["http"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }
      }
    }
  }
}
