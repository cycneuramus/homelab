## Overview

This repository contains the skeleton files for a homelab of self-hosted services orchestrated by [Nomad](https://nomadproject.io). The infrastructure is similar to the one provisioned by [ansible-hybrid-cloud](https://github.com/cycneuramus/ansible-hybrid-cloud).

### Highlights

+ [Caddy](https://caddyserver.com) as [l4 proxy](https://github.com/mholt/caddy-l4) and [fully automated](https://github.com/cycneuramus/homelab/blob/master/caddy/Caddyfile.tpl#L113-L121) reverse proxy
+ [HAProxy](https://www.haproxy.org/) as [internal load balancer](https://github.com/cycneuramus/homelab/blob/master/haproxy/cfg-haproxy.cfg) for infrastructure services
+ Highly available [SeaweedFS](https://github.com/seaweedfs/seaweedfs) deployment for distributed S3 object storage with [auto-failover](https://github.com/cycneuramus/homelab/blob/master/caddy/Caddyfile.tpl#L141-L145) for external endpoints
+ Highly available [PostgreSQL](https://www.postgresql.org) database cluster by means of [Patroni](https://github.com/zalando/patroni)
+ Extensive use of [Nomad service discovery](https://developer.hashicorp.com/nomad/docs/networking/service-discovery) to minimize networking dependencies
+ Self-cleaning [Rclone Docker volumes](https://rclone.org/docker) for cloud storage backends
+ All services aside from the reverse proxy are closed to the outside world, communicating only over a private mesh network
