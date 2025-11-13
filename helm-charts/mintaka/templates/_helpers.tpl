{{/*
Expand the name of the chart.
*/}}
{{- define "application.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "application.fullname" -}}
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

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "application.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Name of the component mintaka.
*/}}
{{- define "mintaka.name" -}}
{{- printf "%s-mintaka" (include "application.name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified component mintaka name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "mintaka.fullname" -}}
{{- printf "%s-mintaka" (include "application.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/*
Component mintaka labels.
*/}}
{{- define "mintaka.labels" -}}
helm.sh/chart: {{ include "application.chart" . }}
{{ include "mintaka.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Component mintaka selector labels.
*/}}
{{- define "mintaka.selectorLabels" -}}
app.kubernetes.io/name: {{ include "application.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: mintaka
isMainInterface: "yes"
tier: {{ .Values.mintaka.tier }}
{{- end }}

{{/*
Name of the component timescaledb.
*/}}
{{- define "timescaledb.name" -}}
{{- printf "%s-timescaledb" (include "application.name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified component timescaledb name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "timescaledb.fullname" -}}
{{- printf "%s-timescaledb" (include "application.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create the default FQDN for timescaledb headless service.
*/}}
{{- define "timescaledb.svc.headless" -}}
{{- printf "%s-headless" (include "timescaledb.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Component timescaledb labels.
*/}}
{{- define "timescaledb.labels" -}}
helm.sh/chart: {{ include "application.chart" . }}
{{ include "timescaledb.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Component timescaledb selector labels.
*/}}
{{- define "timescaledb.selectorLabels" -}}
app.kubernetes.io/name: {{ include "application.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: timescaledb
isMainInterface: "no"
tier: {{ .Values.timescaledb.tier }}
{{- end }}

