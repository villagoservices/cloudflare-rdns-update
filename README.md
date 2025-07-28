# Actualizador autómatico de registros A DNS de Cloudflare

Este proyecto provee un script para actualizar automáticamente el registro DNS A en Cloudflare con la IP externa de tu máquina, ideal para servicios DDNS en entornos domésticos o dinámicos.

## Métodos para ejecutar el script automáticamente

### Método 1: Instalación automática con el instalador (recomendado)

1. Clona el repositorio:

```bash
git clone https://github.com/villagoservices/cloudflare-rdns-update.git
```

2. Entra a la carpeta clonada:
```bash
cd cloudflare-rdns-update
```
3. Dale permiso de ejecución al instalador y ejecútalo como root:
```bash
chmod +x instalador.sh
sudo ./instalador.sh
```
Este instalador:
-   Copia los archivos a la ruta que elijas (por defecto `/cloudflare`).
-   Crea el usuario `ddnsuser` (si no existe).
-   Pide tu correo y API key de Cloudflare para crear el archivo `.env`.
-   Configura los permisos adecuados.
-   Ejecuta una prueba del script.
-   Añade la tarea programada (cron) para que se ejecute cada minuto.

### Método 2: Instalación manual ejecutando los comandos paso a paso

1. Clona el repositorio y copia los archivos a `/cloudflare`:
```bash
git clone https://github.com/villagoservices/cloudflare-rdns-update.git /tmp/cloudflare-temp
sudo mkdir -p /cloudflare
sudo cp -r /tmp/cloudflare-temp/* /tmp/cloudflare-temp/.[!.]* /cloudflare/
sudo rm -rf /tmp/cloudflare-temp
```
2. Crea el usuario `ddnsuser` sin contraseña:
```bash
sudo adduser --disabled-password --gecos "" ddnsuser
```
3. Cambia la propiedad y permisos:
```bash
sudo chown -R ddnsuser:ddnsuser /cloudflare
sudo chmod 700 /cloudflare
sudo chmod 600 /cloudflare/.env
sudo chmod 700 /cloudflare/update_dns_cloudflare.sh
```
4. Crea el archivo `.env` con tus datos (reemplaza con tus valores):
```bash
echo -e "CF_AUTH_EMAIL=tu_correo@example.com\nCF_AUTH_KEY=tu_api_key" | sudo tee /cloudflare/.env
sudo chown ddnsuser:ddnsuser /cloudflare/.env
sudo chmod 600 /cloudflare/.env
```
5. Prueba ejecutar el script como `ddnsuser` (reemplaza dominio y subdominio si quieres):
```bash
sudo -u ddnsuser bash /cloudflare/update_dns_cloudflare.sh midominio.cl www
```
6. Agrega la tarea programada para que se ejecute cada minuto:
```bash
echo "* * * * * bash /cloudflare/update_dns_cloudflare.sh midominio.cl www > /cloudflare/ddns_cloudflare.log 2>&1" | sudo crontab -u ddnsuser -
```

---

## 🙌 ¿Te fue útil este proyecto? ¡Apóyalo con una donación!

Si este script te ahorró tiempo, dolores de cabeza o simplemente te pareció genial, considera apoyar su desarrollo:

☕ **Invítame un café:**

[![Buy Me a Coffee](https://img.shields.io/badge/-Invítame_un_café-ff813f?style=for-the-badge&logo=buy-me-a-coffee&logoColor=white)](https://coff.ee/villago)

💸 **O haz una donación directa por PayPal:**

[![Donate](https://img.shields.io/badge/Donar-PayPal-0070ba?style=for-the-badge&logo=paypal&logoColor=white)](https://www.paypal.com/ncp/payment/K3748XUX2BM5Y)

---
> Tu aporte ayuda a mantener y mejorar este y muchos otros proyectos, ¡gracias por tu apoyo!
