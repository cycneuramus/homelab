alerting:
  custom:
    url: "https://ntfy.example.com"
    method: "POST"
    body: |
      {
        "topic": "cluster",
        "title": "[ENDPOINT_GROUP]",
        "message": "[ENDPOINT_NAME]: [ALERT_TRIGGERED_OR_RESOLVED]",
        "priority": 3
      }
    placeholders:
      ALERT_TRIGGERED_OR_RESOLVED:
        TRIGGERED: "❌ DOWN"
        RESOLVED: "✅ UP"
default-endpoint: &defaults
  group: Services
  interval: 5m
  conditions:
    - "[CONNECTED] == true"
  client:
    timeout: 10s
  ui:
    hide-hostname: true
    hide-url: true
  alerts:
    - type: custom
      enabled: true
      send-on-resolved: true
      failure-threshold: 5
      success-threshold: 2
endpoints:

{{- define "infra" -}}
haproxy
postgres-apex
postgres-green
postgres-vps
s3
s3-filer
s3-master
s3-volume
{{- end -}}

{{- define "networking" -}}
l4-proxy-green
l4-proxy-vps
reverse-proxy-green
reverse-proxy-vps
adguard
unbound
{{- end -}}

{{- define "services" -}}
arcade
audiobooks
change
collabora
git
grocy
hass
immich-server
jellyfin
jellyseerr
kavita
kutt
libreddit
llama
llama-api
mailserver-25
navidrome
nextcloud
nitter
ntfy
prowlarr
rdt
resume
resume-backend
searx
tm
transfer
unmanic
vaultwarden
wizarr
{{- end -}}

{{ range $service := executeTemplate "infra" | split "\n" -}}
{{- $allocID := env "NOMAD_ALLOC_ID" -}}
{{- $upstream := nomadService 1 $allocID $service }}
  - name: {{ $service }}
    !!merge <<: *defaults
    group: Infra
{{- if $upstream -}}
{{- range $upstream }}
    url: tcp://{{ .Address }}:{{ .Port }}{{ end }}
{{- else }}
    url: tcp://localhost:1111
{{- end }}
{{ end }}

{{ range $service := executeTemplate "networking" | split "\n" -}}
{{- $allocID := env "NOMAD_ALLOC_ID" -}}
{{- $upstream := nomadService 1 $allocID $service }}
  - name: {{ $service }}
    !!merge <<: *defaults
    group: Networking
{{- if $upstream -}}
{{- range $upstream }}
    url: tcp://{{ .Address }}:{{ .Port }}{{ end }}
{{- else }}
    url: tcp://localhost:1111
{{- end }}
{{ end }}

{{ range $service := executeTemplate "services" | split "\n" -}}
{{- $allocID := env "NOMAD_ALLOC_ID" -}}
{{- $upstream := nomadService 1 $allocID $service }}
  - name: {{ $service }}
    !!merge <<: *defaults
{{- if $upstream -}}
{{- range $upstream }}
    url: tcp://{{ .Address }}:{{ .Port }}{{ end }}
{{- else }}
    url: tcp://localhost:1111
{{- end }}
{{ end }}
  # - name: Apex
  #   !!merge <<: *defaults
  #   group: Nomad nodes
  #   url: icmp://10.10.10.10

  # - name: Home
  #   !!merge <<: *defaults
  #   group: Nomad nodes
  #   url: icmp://10.10.10.11

  # - name: VPS
  #   !!merge <<: *defaults
  #   group: Nomad nodes
  #   url: icmp://10.10.10.12

  # - name: Green
  #   !!merge <<: *defaults
  #   group: Nomad nodes
  #   url: icmp://10.10.10.13

  # - name: ARM
  #   !!merge <<: *defaults
  #   group: Nomad nodes
  #   url: icmp://10.10.10.14
