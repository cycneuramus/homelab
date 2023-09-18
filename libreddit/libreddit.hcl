locals {
  strg = pathexpand("~/cld/libreddit")
}

job "libreddit" {
  constraint {
    attribute = "${meta.performance}"
    value     = "high"
  }

  constraint {
    attribute = "${attr.cpu.arch}"
    operator  = "!="
    value     = "arm64"
  }

  constraint {
    attribute = "${meta.datacenter}"
    operator  = "!="
    value     = "eso"
  }

  group "libreddit" {
    count = 1

    network {
      port "http" {
        to           = 8080
        host_network = "private"
      }
    }

    task "libreddit" {
      driver = "docker"
      user   = "1000:1000"

      service {
        name     = "libreddit"
        port     = "http"
        provider = "nomad"
        tags     = ["local"]
      }

      template {
        source      = "${local.strg}/.env"
        destination = "env"
        env         = true
      }

      config {
        image = "spikecodes/libreddit:latest"
        ports = ["http"]
      }
    }
  }
}
