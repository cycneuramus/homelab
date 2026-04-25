locals {
  # image = "quay.io/redlib/redlib@sha256:e6647a94d553bf3f7c95c53fc6d9da5785e6c278d9002e99ea32abdb5e3c513a"
  image = "ghcr.io/silvenga/redlib:0.36.0"
  # image = "git.ptr.moe/baalajimaestro/redlib@sha256:06c18c3ae581016e7ba444a9b07e69532fa10aed5c6f04c0c5766dffdffb75e7"
  # image = "ghcr.io/cycneuramus/containers:redlib"
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
