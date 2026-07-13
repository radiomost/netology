{{/*
Chart name
*/}}

{{- define "netology-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}



{{/*
Full resource name.
Important:
Release name included,
so multiple installs in one namespace work.
*/}}

{{- define "netology-app.fullname" -}}

{{- if .Values.fullnameOverride }}

{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}

{{- else }}

{{- printf "%s-%s" .Release.Name (include "netology-app.name" .) | trunc 63 | trimSuffix "-" }}

{{- end }}

{{- end }}



{{/*
Common labels
*/}}

{{- define "netology-app.labels" -}}

helm.sh/chart: {{ include "netology-app.chart" . }}

{{ include "netology-app.selectorLabels" . }}

{{- end }}



{{/*
Selector labels
*/}}

{{- define "netology-app.selectorLabels" -}}

app.kubernetes.io/name: {{ include "netology-app.name" . }}

app.kubernetes.io/instance: {{ .Release.Name }}

{{- end }}



{{/*
Chart version
*/}}

{{- define "netology-app.chart" -}}

{{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}

{{- end }}