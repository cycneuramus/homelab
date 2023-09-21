locals {
  strg = pathexpand("~/wip/patroni")

  etcd_nodes = [
    "etcd-apex=http://10.10.10.10:2380",
    "etcd-vps=http://10.10.10.12:2380",
    "etcd-green=http://10.10.10.13:2380"
  ]

  etcd_peers = join(",", "${local.etcd_nodes}")
}

job "patroni" {
  group "patroni" {
    count = 3

    constraint {
      distinct_hosts = true
    }

    constraint {
      attribute = "${attr.unique.hostname}"
      operator  = "set_contains_any"
      value     = "apex,vps,green"
    }

    network {
      port "etcd-peer" {
        to           = 2380
        static       = 2380
        host_network = "private"
      }

      port "etcd-client" {
        to           = 2379
        static       = 2379
        host_network = "private"
      }

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

    task "etcd" {
      driver = "docker"

      constraint {
        attribute = "${attr.cpu.arch}"
        operator  = "!="
        value     = "arm64"
      }

      lifecycle {
        hook    = "prestart"
        sidecar = true
      }

      template {
        data        = <<-EOF
          ETCD_ADVERTISE_CLIENT_URLS=http://{{ env "NOMAD_ADDR_etcd_client"}}
          ETCD_INITIAL_ADVERTISE_PEER_URLS=http://{{ env "NOMAD_ADDR_etcd_peer" }}
          ETCD_INITIAL_CLUSTER=${local.etcd_peers}
          ETCD_INITIAL_CLUSTER_STATE=new
          ETCD_LISTEN_CLIENT_URLS=http://0.0.0.0:2379
          ETCD_LISTEN_PEER_URLS=http://0.0.0.0:2380
          ETCD_NAME=etcd-{{ env "attr.unique.hostname" }}
        EOF
        destination = "env"
        env         = true
      }

      config {
        image = "quay.io/coreos/etcd"
        ports = ["etcd-peer", "etcd-client"]
      }
    }

    task "patroni" {
      driver       = "docker"
      kill_timeout = "30s"

      resources {
        cpu        = 1000
        memory_max = 2048
      }

      service {
        name     = "postgres-${attr.unique.hostname}"
        port     = "postgres"
        provider = "nomad"
        tags     = ["private"]
      }

      template {
        data        = file("cfg-patroni.yml")
        destination = "local/patroni.yml"
      }

      config {
        image = "ghcr.io/cycneuramus/patroni-docker:latest"
        ports = ["postgres", "patroni"]

        command = "/local/patroni.yml"

        mount {
          type   = "bind"
          source = "${local.strg}/import"
          target = "/home/patroni/import"
        }

        mount {
          type   = "bind"
          source = "${local.strg}/data"
          target = "/home/patroni/data"
        }
      }
    }
  }
}
