## Overview

This repository contains the skeleton files for a homelab of self-hosted services orchestrated by [Nomad](https://nomadproject.io). The infrastructure is similar to the one provisioned by [ansible-hybrid-cloud](https://github.com/cycneuramus/ansible-hybrid-cloud).

### Highlights

+ [Caddy](https://caddyserver.com) as load balancer, [l4 proxy](https://github.com/mholt/caddy-l4), and [fully automated](https://github.com/cycneuramus/homelab/blob/master/caddy/Caddyfile.tpl#L113-L121) reverse proxy
+ Highly available [SeaweedFS](https://github.com/seaweedfs/seaweedfs) deployment for distributed S3 object storage with [auto-failover](https://github.com/cycneuramus/homelab/blob/master/caddy/Caddyfile.tpl#L141-L145) endpoints
+ Highly available Postgres database cluster by means of [Patroni](https://github.com/zalando/patroni)
+ Extensive use of [Nomad service discovery](https://developer.hashicorp.com/nomad/docs/networking/service-discovery) to minimize networking dependencies
+ Self-cleaning [Rclone Docker volumes](https://rclone.org/docker) for cloud storage backends
+ All services aside from the proxies are closed to the outside world, communicating only over a private mesh network
