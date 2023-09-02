locals {
  strg = pathexpand("~/cld/minecraft")
}

job "minecraft" {
  constraint {
    attribute = "${meta.performance}"
    value     = "high"
  }

  constraint {
    attribute = "${meta.datacenter}"
    operator  = "!="
    value     = "ocl"
  }

  group "minecraft" {
    count = 1

    network {
      port "java" {
        to           = 25565
        host_network = "private"
      }

      port "bedrock" {
        to           = 19132
        host_network = "private"
      }
    }

    task "minecraft" {
      driver = "docker"
      user   = "1000:1000"

      resources {
        memory_max = 1500
      }

      service {
        name     = "minecraft-java"
        port     = "java"
        provider = "nomad"
        tags     = ["private", "monitor"]
      }

      service {
        name     = "minecraft-bedrock"
        port     = "bedrock"
        provider = "nomad"
        tags     = ["private", "monitor"]
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      config {
        image = "itzg/minecraft-server"
        ports = ["java", "bedrock"]

        mount {
          type   = "bind"
          source = "${local.strg}/data"
          target = "/data"
        }
      }
    }
  }
}
