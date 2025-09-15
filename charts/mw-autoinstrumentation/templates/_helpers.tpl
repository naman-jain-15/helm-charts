{{/*
Certificate generation logic - handles both cert-manager and auto-generated certs
*/}}
{{- define "mw-auto-injector.webhook-certs" -}}
{{- $caCertEnc := "" }}
{{- $certCrtEnc := "" }}
{{- $certKeyEnc := "" }}

{{- if .Values.webhook.certManager.enabled }}
  {{/* Use cert-manager - certificates will be injected automatically */}}
  {{/* Return empty since cert-manager handles everything */}}
  {{- $result := dict "useCertManager" true }}
  {{- $result | toYaml }}
{{- else if .Values.webhook.autoGenerateCert.enabled }}
  {{/* Auto-generate self-signed certificates */}}
  {{- $secretName := "mw-auto-injector-tls" }}
  {{- $prevSecret := (lookup "v1" "Secret" .Release.Namespace $secretName) }}
  
  {{- if and (not .Values.webhook.autoGenerateCert.recreate) $prevSecret }}
    {{/* Reuse existing certificate */}}
    {{- $certCrtEnc = index $prevSecret "data" "tls.crt" }}
    {{- $certKeyEnc = index $prevSecret "data" "tls.key" }}
    {{- $caCertEnc = index $prevSecret "data" "ca.crt" }}
    
    {{/* If CA is missing, try to get it from existing webhook config */}}
    {{- if not $caCertEnc }}
      {{- $prevHook := (lookup "admissionregistration.k8s.io/v1" "MutatingWebhookConfiguration" "" "mw-auto-injector.acme.com") }}
      {{- if $prevHook }}
        {{- if $prevHook.webhooks }}
          {{- $caCertEnc = (first $prevHook.webhooks).clientConfig.caBundle }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- else }}
    {{/* Generate new certificates */}}
    {{- $serviceName := "mw-auto-injector" }}
    {{- $clusterDomain := .Values.clusterDomain | default "cluster.local" }}
    {{- $altNames := list 
        (printf "%s.%s" $serviceName .Release.Namespace)
        (printf "%s.%s.svc" $serviceName .Release.Namespace)
        (printf "%s.%s.svc.%s" $serviceName .Release.Namespace $clusterDomain) }}
    
    {{- $certPeriod := int (.Values.webhook.autoGenerateCert.certPeriodDays | default 365) }}
    {{- $ca := genCA (printf "%s-ca" $serviceName) $certPeriod }}
    {{- $cert := genSignedCert $serviceName nil $altNames $certPeriod $ca }}
    
    {{- $certCrtEnc = b64enc $cert.Cert }}
    {{- $certKeyEnc = b64enc $cert.Key }}
    {{- $caCertEnc = b64enc $ca.Cert }}
  {{- end }}
  
  {{- $result := dict "crt" $certCrtEnc "key" $certKeyEnc "ca" $caCertEnc "useCertManager" false }}
  {{- $result | toYaml }}
{{- else }}
  {{/* Manual certificate files */}}
  {{/* No certificate management enabled - return empty values */}}
  {{- $result := dict "crt" "" "key" "" "ca" "" "useCertManager" false }}
  {{- $result | toYaml }}
{{- end }}
{{- end }}