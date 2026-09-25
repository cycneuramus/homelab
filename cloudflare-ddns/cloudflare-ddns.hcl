locals {
  image = "docker.io/favonia/cloudflare-ddns:1.17.1"
}

job "cloudflare-ddns" {
  group "cloudflare-ddns" {
    task "cloudflare-ddns" {
      driver = "podman"
      user   = "1000:1000"

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      config {
        image  = "${local.image}"
        userns = "keep-id"
      }
    }
  }
}
