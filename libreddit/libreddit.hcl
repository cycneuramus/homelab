locals {
  # image = "quay.io/redlib/redlib@sha256:37f624d87ce6cdd90d945af3688fdf0c195a0251d3b5ba62047792e8be2390df"
  image = "ghcr.io/nachtalb/redlib@sha256:23b160325aa878ba25915bcecf0694beee79664474b21286101af45e3c0693d3"
  # image = "git.ptr.moe/baalajimaestro/redlib@sha256:197a0bc6b3eafbb7154cd739eaa832ddbf4a2ff5ce5ab119d6e2ec00f6581449"
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

      resources {
        memory_max = 1024
      }

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
      }
    }
  }
}
