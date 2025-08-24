{{- define "dashy.name" -}}
dashy
{{- end -}}

{{- define "dashy.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name (include "dashy.name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end -}}
