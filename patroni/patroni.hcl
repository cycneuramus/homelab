locals {
  strg = pathexpand("~/.local/share/patroni")
  image = {
    etcd    = "gcr.io/etcd-development/etcd:v3.6.8"
    patroni = "ghcr.io/cycneuramus/containers:patroni"
  }
}

job "patroni" {
  group "etcd" {
    count = 1

    network {
      port "etcd-peer" {
        to           = 2380
        host_network = "private"
      }

      port "etcd-client" {
        to           = 2379
        host_network = "private"
      }
    }

    task "etcd" {
      driver = "podman"

      service {
        name         = "etcd"
        port         = "etcd-client"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["private", "monitor:databases"]
      }

      template {
        data        = <<-EOF
          ALLOW_NONE_AUTHENTICATION=yes
          ETCD_ADVERTISE_CLIENT_URLS=http://{{ env "NOMAD_ADDR_etcd_client"}}
          ETCD_DATA_DIR=/etcd-data
          ETCD_INITIAL_ADVERTISE_PEER_URLS=http://{{ env "NOMAD_ADDR_etcd_peer" }}
          ETCD_INITIAL_CLUSTER=etcd=http://{{ env "NOMAD_ADDR_etcd_peer" }}
          ETCD_LISTEN_CLIENT_URLS=http://0.0.0.0:{{ env "NOMAD_PORT_etcd_client" }}
          ETCD_LISTEN_PEER_URLS=http://0.0.0.0:{{ env "NOMAD_PORT_etcd_peer" }}
          ETCD_NAME=etcd
        EOF
        destination = "env"
        env         = true
      }

      config {
        image = "${local.image.etcd}"
        ports = ["etcd-peer", "etcd-client"]

        logging = {
          driver = "journald"
        }
      }
    }
  }

  group "patroni" {
    count = 3

    constraint {
      distinct_hosts = true
    }

    constraint {
      attribute = "${attr.unique.hostname}"
      operator  = "set_contains_any"
      value     = "apex,ambi,horreum"
    }

    update {
      max_parallel = 1
    }

    network {
      port "patroni" {
        to           = 8008
        static       = 8008
        host_network = "private"
      }

      port "postgres" {
        to           = 5432
        host_network = "private"
      }
    }

    task "preflight" {
      driver = "raw_exec"
      user   = "antsva"

      lifecycle {
        hook    = "prestart"
        sidecar = false
      }

      template {
        data        = <<-EOF
          #!/bin/sh
          mkdir -p ${local.strg}/data
          {{ range nomadService "etcd" }}
          until nc -z {{ .Address }} {{ .Port }}; do sleep 1; done
          {{ end -}}
        EOF
        destination = "local/preflight.sh"
        perms       = 755
      }

      config {
        command = "local/preflight.sh"
      }
    }

    task "patroni" {
      driver       = "podman"
      kill_timeout = "30s"

      resources {
        cpu        = 1000
        memory_max = 2048
      }

      service {
        name         = "postgres-${attr.unique.hostname}"
        port         = "postgres"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["private", "monitor:databases"]
      }

      template {
        data        = file("cfg-patroni.yml")
        destination = "local/patroni.yml"
        uid         = 1000
        gid         = 1000
      }

      config {
        image   = "${local.image.patroni}"
        ports   = ["postgres", "patroni"]
        command = "/local/patroni.yml"

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/data:/home/patroni/data"
        ]
      }
    }
  }
}
