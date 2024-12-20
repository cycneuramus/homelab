storage:
  type: postgres
  path: "postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@{{ env "attr.unique.network.ip-address" }}:15432/gatus?sslmode=disable"
  caching: true

alerting:
  custom:
    url: "https://ntfy.${DOMAIN}"
    method: "POST"
    body: |
      {
        "topic": "cluster",
        "title": "[ENDPOINT_NAME]",
        "message": "[ALERT_TRIGGERED_OR_RESOLVED]",
        "priority": 3
      }
    placeholders:
      ALERT_TRIGGERED_OR_RESOLVED:
        TRIGGERED: "🔴 DOWN"
        RESOLVED: "🟢 UP"

service-endpoint: &services
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
      failure-threshold: 2
      success-threshold: 2

endpoints:

{{- define "databases" -}}
etcd
keydb-ambi
keydb-apex
keydb-horreum
postgres-ambi
postgres-apex
postgres-horreum
{{- end -}}

{{- define "infra" -}}
caddy-apex
caddy-ambi
caddy-horreum
haproxy-apex
haproxy-ambi
haproxy-horreum
s3-apex
s3-ambi
s3-horreum
{{- end -}}

{{- define "proxying" -}}
change
flaresolverr
kutt
libreddit
searx
{{- end -}}

{{- define "communication" -}}
imaps
matrix
meet
ntfy
signal-bridge
signal-cli-rest-api
smtp
smtps
stalwart
{{- end -}}

{{- define "personal" -}}
fmd
grocy
hannes
hass
immich
resume
resume-backend
vaultwarden
{{- end -}}

{{- define "collaboration" -}}
collabora
filestash
gist
git
nextcloud
rallly
transfer
{{- end -}}

{{- define "entertainment" -}}
arcade
audiobooks
jellyfin
navidrome
tm
{{- end -}}

{{- define "curation" -}}
bazarr
jellyseerr
jellystat
pinchflat
prowlarr
radarr
rdt
sonarr
soulseek
unmanic
wizarr
{{- end }}

  - name: turn
    !!merge <<: *services
    group: 05. Communication
    url: tcp://${TURN_IP}:3478

  - name: apex
    !!merge <<: *services
    group: 01. Nomad nodes
    url: http://10.10.10.10:4646/v1/agent/health
    conditions:
      - "[STATUS] == 200"

  - name: ambi
    !!merge <<: *services
    group: 01. Nomad nodes
    url: http://10.10.10.11:4646/v1/agent/health
    conditions:
      - "[STATUS] == 200"

  - name: horreum
    !!merge <<: *services
    group: 01. Nomad nodes
    url: http://10.10.10.12:4646/v1/agent/health
    conditions:
      - "[STATUS] == 200"

{{ range $service := executeTemplate "databases" | split "\n" -}}
{{- $allocID := env "NOMAD_ALLOC_ID" -}}
{{- $upstream := nomadService 1 $allocID $service }}
  - name: {{ $service }}
    !!merge <<: *services
    group: 02. Databases
{{- if $upstream -}}
{{- range $upstream }}
    url: tcp://{{ .Address }}:{{ .Port }}{{ end }}
{{- else }}
    url: tcp://localhost:1111
{{- end }}
{{ end }}

{{ range $service := executeTemplate "infra" | split "\n" -}}
{{- $allocID := env "NOMAD_ALLOC_ID" -}}
{{- $upstream := nomadService 1 $allocID $service }}
  - name: {{ $service }}
    !!merge <<: *services
    group: 03. Infra
{{- if $upstream -}}
{{- range $upstream }}
    url: tcp://{{ .Address }}:{{ .Port }}{{ end }}
{{- else }}
    url: tcp://localhost:1111
{{- end }}
{{ end }}

{{ range $service := executeTemplate "proxying" | split "\n" -}}
{{- $allocID := env "NOMAD_ALLOC_ID" -}}
{{- $upstream := nomadService 1 $allocID $service }}
  - name: {{ $service }}
    !!merge <<: *services
    group: 04. Proxying
{{- if $upstream -}}
{{- range $upstream }}
    url: tcp://{{ .Address }}:{{ .Port }}{{ end }}
{{- else }}
    url: tcp://localhost:1111
{{- end }}
{{ end }}

{{ range $service := executeTemplate "communication" | split "\n" -}}
{{- $allocID := env "NOMAD_ALLOC_ID" -}}
{{- $upstream := nomadService 1 $allocID $service }}
  - name: {{ $service }}
    !!merge <<: *services
    group: 05. Communication
{{- if $upstream -}}
{{- range $upstream }}
    url: tcp://{{ .Address }}:{{ .Port }}{{ end }}
{{- else }}
    url: tcp://localhost:1111
{{- end }}
{{ end }}

{{ range $service := executeTemplate "personal" | split "\n" -}}
{{- $allocID := env "NOMAD_ALLOC_ID" -}}
{{- $upstream := nomadService 1 $allocID $service }}
  - name: {{ $service }}
    !!merge <<: *services
    group: 06. Personal
{{- if $upstream -}}
{{- range $upstream }}
    url: tcp://{{ .Address }}:{{ .Port }}{{ end }}
{{- else }}
    url: tcp://localhost:1111
{{- end }}
{{ end }}

{{ range $service := executeTemplate "collaboration" | split "\n" -}}
{{- $allocID := env "NOMAD_ALLOC_ID" -}}
{{- $upstream := nomadService 1 $allocID $service }}
  - name: {{ $service }}
    !!merge <<: *services
    group: 07. Collaboration
{{- if $upstream -}}
{{- range $upstream }}
    url: tcp://{{ .Address }}:{{ .Port }}{{ end }}
{{- else }}
    url: tcp://localhost:1111
{{- end }}
{{ end }}

{{ range $service := executeTemplate "entertainment" | split "\n" -}}
{{- $allocID := env "NOMAD_ALLOC_ID" -}}
{{- $upstream := nomadService 1 $allocID $service }}
  - name: {{ $service }}
    !!merge <<: *services
    group: 08. Entertainment
{{- if $upstream -}}
{{- range $upstream }}
    url: tcp://{{ .Address }}:{{ .Port }}{{ end }}
{{- else }}
    url: tcp://localhost:1111
{{- end }}
{{ end }}

{{ range $service := executeTemplate "curation" | split "\n" -}}
{{- $allocID := env "NOMAD_ALLOC_ID" -}}
{{- $upstream := nomadService 1 $allocID $service }}
  - name: {{ $service }}
    !!merge <<: *services
    group: 09. Curation
{{- if $upstream -}}
{{- range $upstream }}
    url: tcp://{{ .Address }}:{{ .Port }}{{ end }}
{{- else }}
    url: tcp://localhost:1111
{{- end }}
{{ end }}
