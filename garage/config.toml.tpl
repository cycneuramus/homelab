replication_factor = 3
consistency_mode = "consistent"

metadata_dir = "/var/lib/garage/meta"
data_dir = "/var/lib/garage/data"

db_engine = "lmdb"
# lmdb_map_size = "1GiB"

compression_level = 1

rpc_bind_addr = "[::]:{{ env "NOMAD_PORT_rpc" }}"
rpc_public_addr = "{{ env "NOMAD_IP_rpc" }}:{{ env "NOMAD_PORT_rpc" }}"

[s3_api]
s3_region = "us-east-1" # expected by litestream
api_bind_addr = "[::]:{{ env "NOMAD_PORT_s3" }}"
root_domain = ".s3.garage"

[admin]
api_bind_addr = "0.0.0.0:3903"
