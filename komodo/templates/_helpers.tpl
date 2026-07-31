{{- define "komodo.name" -}}{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}{{- end }}
{{- define "komodo.fullname" -}}{{- if .Values.fullnameOverride }}{{ .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}{{- else }}{{- printf "%s-%s" .Release.Name (include "komodo.name" .) | trunc 63 | trimSuffix "-" }}{{- end }}{{- end }}
{{- define "komodo.labels" -}}app.kubernetes.io/name: {{ include "komodo.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}{{- end }}
{{- define "komodo.secretName" -}}{{- default (printf "%s-secrets" (include "komodo.fullname" .)) .Values.existingSecret.name }}{{- end }}
{{- define "komodo.mongoName" -}}{{- printf "%s-mongo" (include "komodo.fullname" .) }}{{- end }}

{{/* Return the address used by Komodo Core for MongoDB. */}}
{{- define "komodo.mongoAddress" -}}
{{- if eq .Values.mongo.mode "external" -}}
{{- printf "%s:%d" (required "mongo.host is required when mongo.mode=external" .Values.mongo.host) (int .Values.mongo.port) -}}
{{- else -}}
{{- printf "%s:27017" (include "komodo.mongoName" .) -}}
{{- end -}}
{{- end -}}

{{/* Validate only the new mode selector and external endpoint. */}}
{{- define "komodo.validateMongo" -}}
{{- if not (has .Values.mongo.mode (list "embedded" "external")) -}}
{{- fail (printf "mongo.mode must be embedded or external, got %q" .Values.mongo.mode) -}}
{{- end -}}
{{- if and (eq .Values.mongo.mode "external") (not .Values.mongo.host) -}}
{{- fail "mongo.host is required when mongo.mode=external" -}}
{{- end -}}
{{- end -}}
