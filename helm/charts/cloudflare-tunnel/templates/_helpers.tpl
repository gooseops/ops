{{/* vim: set filetype=mustache: */}}
{{/*
Setup a chart name
*/}}
{{- define "cloudflare_tunnel.name" -}}
{{- default .Release.Name .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}