#!/bin/bash
# DDNS updater para Cloudflare
# Autor: Daniel V.G
# Fecha: 07-2025
# Usage: ./update_dns_cloudflare.sh zona subdominio (ej: midominio.com casa) o (ej:midominio.com)
# Variables sensibles se cargan desde un archivo .env externo


set -euo pipefail

# === Evitar ejecución como root ===
if [[ "$EUID" -eq 0 ]]; then
  echo "❌ Este script no debe ejecutarse como root. Usa un usuario limitado como 'ddnsuser'."
  exit 1
fi

# === Ruta al archivo .env ===
ENV_FILE="$(dirname "$0")/.env"

if [[ ! -f "$ENV_FILE" ]]; then
    echo "❌ Archivo .env no encontrado en $ENV_FILE"
    exit 1
fi

# === Cargar variables de entorno desde .env ===
export $(grep -v '^#' "$ENV_FILE" | xargs)

# === Verificar dependencias ===
for cmd in curl jq host; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "❌ Falta el comando '$cmd'. Instálalo antes de continuar."
    exit 1
  fi
done

# === Leer argumentos ===
zone="${1:-}"
subdomain="${2:-}"

if [[ -z "$zone" ]]; then
    echo "❌ Uso: $0 zona [subdominio]"
    exit 1
fi

# Validar formato de zona y subdominio
if [[ ! "$zone" =~ ^[a-zA-Z0-9.-]+$ ]] || [[ -n "$subdomain" && ! "$subdomain" =~ ^[a-zA-Z0-9.-]+$ ]]; then
    echo "❌ Error: zona o subdominio con formato inválido"
    exit 1
fi

# Construir nombre completo del registro
dnsrecord="$zone"
if [[ -n "$subdomain" ]]; then
    dnsrecord="$subdomain.$zone"
fi

# === Obtener IP pública ===
ip=$(curl -s https://checkip.amazonaws.com)
echo "🌐 IP pública actual: $ip"

# Verificar si ya está actualizado
if host "$dnsrecord" 1.1.1.1 | grep "has address" | grep -q "$ip"; then
    echo "✅ $dnsrecord ya apunta a $ip. No es necesario actualizar."
    exit 0
fi

# === Obtener Zone ID ===
zoneid=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$zone&status=active" \
  -H "X-Auth-Email: $CF_AUTH_EMAIL" \
  -H "X-Auth-Key: $CF_AUTH_KEY" \
  -H "Content-Type: application/json" \
  | jq -r '.result[0].id')

if [[ "$zoneid" == "null" || -z "$zoneid" ]]; then
    echo "❌ No se pudo obtener el Zone ID para $zone"
    exit 1
fi

# === Obtener DNS Record ID ===
dnsrecordid=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records?type=A&name=$dnsrecord" \
  -H "X-Auth-Email: $CF_AUTH_EMAIL" \
  -H "X-Auth-Key: $CF_AUTH_KEY" \
  -H "Content-Type: application/json" \
  | jq -r '.result[0].id')

if [[ "$dnsrecordid" == "null" || -z "$dnsrecordid" ]]; then
    echo "❌ No se pudo obtener el DNS Record ID para $dnsrecord"
    exit 1
fi

# === Actualizar registro DNS ===
echo "🔄 Actualizando $dnsrecord con IP $ip..."
curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records/$dnsrecordid" \
  -H "X-Auth-Email: $CF_AUTH_EMAIL" \
  -H "X-Auth-Key: $CF_AUTH_KEY" \
  -H "Content-Type: application/json" \
  --data "{\"type\":\"A\",\"name\":\"$dnsrecord\",\"content\":\"$ip\",\"ttl\":1,\"proxied\":true}" \
  | jq

logger "✅ Cloudflare DDNS actualizado: $dnsrecord → $ip"
