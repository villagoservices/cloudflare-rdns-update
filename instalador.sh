#!/bin/bash
# Instalador de DDNS updater para Cloudflare
# Autor: Daniel V.G
# Fecha: 07-2025

set -e

# Valores por defecto
DEFAULT_INSTALL_DIR="/cloudflare"
DEFAULT_DDNS_USER="ddnsuser"
DEFAULT_DOMAIN="midominio.cl"
DEFAULT_SUBDOMAIN="www"
REPO_URL="https://github.com/villagoservices/cloudflare-rdns-update.git"

# Pedir directorio de instalación
read -rp "📁 Ruta de instalación [$DEFAULT_INSTALL_DIR]: " INSTALL_DIR
INSTALL_DIR=${INSTALL_DIR:-$DEFAULT_INSTALL_DIR}

# Pedir usuario
read -rp "👤 Usuario para ejecutar el script [$DEFAULT_DDNS_USER]: " DDNS_USER
DDNS_USER=${DDNS_USER:-$DEFAULT_DDNS_USER}

# Pedir dominio para prueba y cron
read -rp "🌐 Dominio para prueba y cron [$DEFAULT_DOMAIN]: " DOMAIN
DOMAIN=${DOMAIN:-$DEFAULT_DOMAIN}

# Pedir subdominio para prueba y cron
read -rp "🏷️ Subdominio para prueba y cron [$DEFAULT_SUBDOMAIN]: " SUBDOMAIN
SUBDOMAIN=${SUBDOMAIN:-$DEFAULT_SUBDOMAIN}

# Verificar si la carpeta existe
if [[ -d "$INSTALL_DIR" ]]; then
  echo "❌ La carpeta $INSTALL_DIR ya existe. Instalación detenida para evitar sobrescribir."
  exit 1
fi

echo "📥 Clonando repositorio en $INSTALL_DIR..."
git clone "$REPO_URL" "$INSTALL_DIR"

# Crear usuario si no existe
if id -u "$DDNS_USER" >/dev/null 2>&1; then
  echo "👤 Usuario '$DDNS_USER' ya existe."
else
  echo "👤 Creando usuario '$DDNS_USER' sin contraseña..."
  sudo adduser --disabled-password --gecos "" "$DDNS_USER"
fi

# Pedir datos para .env
read -rp "✉️  Ingresa tu correo de Cloudflare (CF_AUTH_EMAIL): " cf_email
read -rsp "🔑 Ingresa tu API Key de Cloudflare (CF_AUTH_KEY): " cf_key
echo ""

# Crear archivo .env
cat > "$INSTALL_DIR/.env" <<EOF
CF_AUTH_EMAIL=$cf_email
CF_AUTH_KEY=$cf_key
EOF

# Ajustar permisos
echo "🔒 Configurando permisos y propietarios..."
sudo chown -R "$DDNS_USER":"$DDNS_USER" "$INSTALL_DIR"
sudo chmod 700 "$INSTALL_DIR"
sudo chmod 600 "$INSTALL_DIR/.env"
sudo chmod 700 "$INSTALL_DIR/update_dns_cloudflare.sh"

# Ejecutar prueba del script como ddnsuser
echo "🧪 Probando script como usuario $DDNS_USER..."
sudo -u "$DDNS_USER" bash "$INSTALL_DIR/update_dns_cloudflare.sh" "$DOMAIN" "$SUBDOMAIN"

# Instalar cronjob para ddnsuser
echo "⏰ Instalando cronjob para usuario $DDNS_USER..."
(crontab -u "$DDNS_USER" -l 2>/dev/null || true; echo "* * * * * bash $INSTALL_DIR/update_dns_cloudflare.sh $DOMAIN $SUBDOMAIN > $INSTALL_DIR/ddns_cloudflare.log 2>&1") | sudo crontab -u "$DDNS_USER" -

echo "✅ Instalación completada con éxito."
echo "El script se ejecutará cada minuto para actualizar la IP en Cloudflare."
echo "Logs en: $INSTALL_DIR/ddns_cloudflare.log"