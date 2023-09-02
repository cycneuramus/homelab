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
{{ range nomadServices -}}
{{- range nomadService .Name -}}
{{- if .Tags | contains "monitor" }}
  - name: {{ .Name }}
    !!merge <<: *defaults
    group: Services
    url: tcp://{{ .Address }}:{{ .Port }}
{{ end -}}
{{- end -}}
{{- end -}}
