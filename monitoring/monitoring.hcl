locals {
  strg = pathexpand("~/cld/prometheus")
}

job "monitoring" {
  constraint {
    attribute = "${meta.performance}"
    value     = "high"
  }

  group "monitoring" {
    count = 1

    network {
      port "prometheus" {
        to           = 9090
        host_network = "private"
      }
      port "grafana" {
        to           = 3000
        host_network = "private"
      }
    }

    task "prometheus" {
      driver = "docker"

      resources {
        memory_max = 1024
      }

      service {
        name     = "prometheus"
        port     = "prometheus"
        provider = "nomad"
        tags     = ["local"]
      }

      template {
        data        = file("prometheus.yml.tpl")
        destination = "/local/config.yml"
      }

      config {
        image = "quay.io/prometheus/prometheus"
        args  = ["--config.file=/local/config.yml"]
        ports = ["prometheus"]
      }
    }

    task "grafana" {
      driver = "docker"

      service {
        name     = "grafana"
        port     = "grafana"
        provider = "nomad"
        tags     = ["local"]
      }

      # TODO:
      # env {
      #   GF_PATHS_CONFIG = "/local/grafana.ini"
      #   GF_PATHS_PROVISIONING = "/local/provisioning"
      # }
      #
      # template {
      #   data = file("grafana.ini")
      #   destination = "local/grafana.ini"
      # }
      #
      # dynamic "template" {
      #   for_each = fileset(".", "provisioning/**")
      #
      #   content {
      #     data        = file(template.value)
      #     destination = "local/${template.value}"
      #   }
      # }

      config {
        image = "grafana/grafana-oss"
        ports = ["grafana"]
      }
    }
  }
}
