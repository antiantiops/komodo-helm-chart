{{- define "komodo.name" -}}{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}{{- end }}
{{- define "komodo.fullname" -}}{{- if .Values.fullnameOverride }}{{ .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}{{- else }}{{- printf "%s-%s" .Release.Name (include "komodo.name" .) | trunc 63 | trimSuffix "-" }}{{- end }}{{- end }}
{{- define "komodo.labels" -}}app.kubernetes.io/name: {{ include "komodo.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}{{- end }}
{{- define "komodo.secretName" -}}{{- default (printf "%s-secrets" (include "komodo.fullname" .)) .Values.existingSecret.name }}{{- end }}
{{- define "komodo.mongoName" -}}{{- printf "%s-mongo" (include "komodo.fullname" .) }}{{- end }}
