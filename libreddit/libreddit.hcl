locals {
  # image = "quay.io/redlib/redlib@sha256:37f624d87ce6cdd90d945af3688fdf0c195a0251d3b5ba62047792e8be2390df"
  # image = "ghcr.io/nachtalb/redlib:sha-fca8b45"
  image = "ghcr.io/polak14/redlib@sha256:089c7b24c08bb49c725f65bfc10f52ed034811d51eb576190e3e20988a6d0052"
  # image = "git.ptr.moe/baalajimaestro/redlib@sha256:1c605c3af39855b77d3f81fc01343b30ed21bd1bf8764bdf9c095e0b35da57b5"
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
