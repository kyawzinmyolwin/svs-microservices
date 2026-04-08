{{- define "svs-microservices.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "svs-microservices.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "svs-microservices.labels" -}}
helm.sh/chart: {{ include "svs-microservices.name" . }}-{{ .Chart.Version | replace "+" "_" }}
{{ include "svs-microservices.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "svs-microservices.selectorLabels" -}}
app.kubernetes.io/name: {{ include "svs-microservices.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "svs-microservices.namespace" -}}
{{- .Values.namespace }}
{{- end }}
