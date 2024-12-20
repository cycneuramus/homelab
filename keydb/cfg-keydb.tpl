port 16380
bind 0.0.0.0
unixsocket /tmp/sock/keydb.sock
unixsocketperm 770

appendonly yes
save 900 1
save 300 10

active-replica yes
multi-master yes
repl-backlog-size 300mb
repl-timeout 300

client-output-buffer-limit normal 0 0 0
client-output-buffer-limit pubsub 0 0 0
client-output-buffer-limit replica 0 0 0

{{- $ip_self := env "attr.unique.network.ip-address" -}}
{{- $ip_apex := "10.10.10.10" -}}
{{- $ip_ambi := "10.10.10.11" -}}
{{- $ip_horreum := "10.10.10.12" }}

{{ if ne $ip_self $ip_apex -}}
replicaof {{ $ip_apex }} 16380
{{- end }}

{{ if ne $ip_self $ip_ambi -}}
replicaof {{ $ip_ambi }} 16380
{{- end }}

{{ if ne $ip_self $ip_horreum -}}
replicaof {{ $ip_horreum }} 16380
{{- end }}
