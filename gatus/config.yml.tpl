storage:
  type: postgres
  path: "postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@{{ env "attr.unique.network.ip-address" }}:15432/gatus?sslmode=disable"
  caching: true

ui:
  default-sort-by: group

alerting:
  custom:
    url: "https://ntfy.${DOMAIN}"
    method: "POST"
    headers:
      Authorization: "Bearer ${PUSH_TOKEN}"
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
hannes-db
postgres-ambi
postgres-apex
postgres-horreum
valkey
{{- end -}}

{{- define "network" -}}
caddy-ambi
caddy-apex
caddy-horreum
coredns-ambi
coredns-apex
coredns-horreum
haproxy-ambi
haproxy-apex
haproxy-horreum
{{- end -}}

{{- define "storage" -}}
s3-ambi
s3-apex
s3-horreum
{{- end -}}

{{- define "security" -}}
auth
fmd
honeypot
oidc
vaultwarden
{{- end -}}

{{- define "monitoring" -}}
beszel
ghrm
{{- end -}}

{{- define "proxying" -}}
ai
change
flaresolverr
gpt
kutt
libreddit
searx
{{- end -}}

{{- define "communication" -}}
imaps
matrix
meet
ntfy
signal-api
signal-bridge
smtp
smtps
stalwart
whatsapp-bridge
{{- end -}}

{{- define "personal" -}}
dbh
diogenes
fitness
grocy
hannes
hass
immich
mood
pin
resume
resume-backend
rss
timelapse
{{- end -}}

{{- define "collaboration" -}}
collabora
dav
gist
git
ihatemoney
opencloud
rallly
transfer
wopi
{{- end -}}

{{- define "entertainment" -}}
audiobooks
cwa
jellyfin
koinsight
koito
multi-scrobbler
navidrome
roms
tm
{{- end -}}

{{- define "curation" -}}
bazarr
beets
jellyseerr
prowlarr
radarr
sabnzbd
shelfmark
sonarr
soulseek
unmanic
wizarr
{{- end }}

  - name: turn
    !!merge <<: *services
    group: 08. Communication
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

{{ range $service := executeTemplate "network" | split "\n" -}}
{{- $allocID := env "NOMAD_ALLOC_ID" -}}
{{- $upstream := nomadService 1 $allocID $service }}
  - name: {{ $service }}
    !!merge <<: *services
    group: 03. Network
{{- if $upstream -}}
{{- range $upstream }}
    url: tcp://{{ .Address }}:{{ .Port }}{{ end }}
{{- else }}
    url: tcp://localhost:1111
{{- end }}
{{ end }}

{{ range $service := executeTemplate "storage" | split "\n" -}}
{{- $allocID := env "NOMAD_ALLOC_ID" -}}
{{- $upstream := nomadService 1 $allocID $service }}
  - name: {{ $service }}
    !!merge <<: *services
    group: 04. Storage
{{- if $upstream -}}
{{- range $upstream }}
    url: tcp://{{ .Address }}:{{ .Port }}{{ end }}
{{- else }}
    url: tcp://localhost:1111
{{- end }}
{{ end }}

{{ range $service := executeTemplate "security" | split "\n" -}}
{{- $allocID := env "NOMAD_ALLOC_ID" -}}
{{- $upstream := nomadService 1 $allocID $service }}
  - name: {{ $service }}
    !!merge <<: *services
    group: 05. Security
{{- if $upstream -}}
{{- range $upstream }}
    url: tcp://{{ .Address }}:{{ .Port }}{{ end }}
{{- else }}
    url: tcp://localhost:1111
{{- end }}
{{ end }}

{{ range $service := executeTemplate "monitoring" | split "\n" -}}
{{- $allocID := env "NOMAD_ALLOC_ID" -}}
{{- $upstream := nomadService 1 $allocID $service }}
  - name: {{ $service }}
    !!merge <<: *services
    group: 06. Monitoring
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
    group: 07. Proxying
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
    group: 08. Communication
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
    group: 09. Personal
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
    group: 10. Collaboration
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
    group: 11. Entertainment
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
    group: 12. Curation
{{- if $upstream -}}
{{- range $upstream }}
    url: tcp://{{ .Address }}:{{ .Port }}{{ end }}
{{- else }}
    url: tcp://localhost:1111
{{- end }}
{{ end }}
