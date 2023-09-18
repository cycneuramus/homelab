locals {
  strg   = pathexpand("~/cld/llama")
  models = pathexpand("~/ai/models")
  model  = "Wizard-Vicuna-13B-Uncensored.ggml.q5_1.bin"
}

job "llama" {
  constraint {
    attribute = "${attr.unique.hostname}"
    value     = "apex"
  }

  group "llama" {
    count = 1

    network {
      port "api" {
        to           = 8000
        host_network = "private"
      }

      port "ui" {
        to           = 3000
        host_network = "private"
      }
    }

    task "api" {
      driver = "docker"

      resources {
        memory_max = 24000
      }

      service {
        name     = "llama-api"
        port     = "api"
        provider = "nomad"
        tags     = ["local"]
      }

      env {
        CACHE      = "1"
        HOST       = "0.0.0.0"
        PORT       = "8000"
        MODEL      = "/models/${local.model}"
        MAX_TOKENS = "2048"
        N_THREADS  = "8"
      }

      config {
        image = "ghcr.io/cycneuramus/llama-cpp-python"
        ports = ["api"]

        mount {
          type   = "bind"
          source = "${local.models}"
          target = "/models"
        }

        devices = [
          {
            host_path = "/dev/dri"
          }
        ]
      }
    }

    task "ui" {
      driver = "docker"

      service {
        name     = "llama"
        port     = "ui"
        provider = "nomad"
        tags     = ["local"]
      }

      env {
        OPENAI_API_HOST = "http://${NOMAD_ADDR_api}"
        OPENAI_API_KEY  = "/llama.cpp/models/${local.model}"
      }

      config {
        image = "ghcr.io/mckaywrigley/chatbot-ui:main"
        ports = ["ui"]

        mount {
          type   = "bind"
          source = "${local.models}"
          target = "/llama.cpp/models"
        }
      }
    }
  }
}
