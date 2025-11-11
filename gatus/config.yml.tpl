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

{{ define "emit_category_endpoints" -}}
{{- $category := .category -}}
{{- $group := .group -}}
{{- $want := printf "monitor:%s" $category -}}
{{- $allocID := env "NOMAD_ALLOC_ID" -}}
{{- range $svc := nomadServices -}}
  {{- $svcName := $svc.Name -}}
  {{- $has := false -}}
  {{- range $tag := $svc.Tags -}}
    {{- if eq $tag $want -}} {{- $has = true -}} {{- end -}}
  {{- end -}}
  {{- if $has -}}
    {{- $up := nomadService 1 $allocID $svcName }}
  - name: {{ $svcName }}
    !!merge <<: *services
    group: {{ $group }}
    {{- if $up -}}
    {{ range $up }}
    url: tcp://{{ .Address }}:{{ .Port }}
    {{ end }}
    {{- else -}}
    url: tcp://localhost:1111
    {{ end }}
  {{- end -}}
{{- end -}}
{{- end -}}

endpoints:
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

{{ template "emit_category_endpoints" (sprig_dict "category" "databases" "group" "02. Databases") }}
{{ template "emit_category_endpoints" (sprig_dict "category" "network" "group" "03. Network") }}
{{ template "emit_category_endpoints" (sprig_dict "category" "storage" "group" "04. Storage") }}
{{ template "emit_category_endpoints" (sprig_dict "category" "security" "group" "05. Security") }}
{{ template "emit_category_endpoints" (sprig_dict "category" "monitoring" "group" "06. Monitoring") }}
{{ template "emit_category_endpoints" (sprig_dict "category" "proxying" "group" "07. Proxying") }}
{{ template "emit_category_endpoints" (sprig_dict "category" "communication" "group" "08. Communication") }}
{{ template "emit_category_endpoints" (sprig_dict "category" "personal" "group" "09. Personal") }}
{{ template "emit_category_endpoints" (sprig_dict "category" "collaboration" "group" "10. Collaboration") }}
{{ template "emit_category_endpoints" (sprig_dict "category" "entertainment" "group" "11. Entertainment") }}
{{ template "emit_category_endpoints" (sprig_dict "category" "curation" "group" "12. Curation") }}
