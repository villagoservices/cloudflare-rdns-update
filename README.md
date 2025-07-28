





sudo adduser --disabled-password --gecos "" ddnsuser
sudo chown -R ddnsuser:ddnsuser /cloudflare
sudo chmod 700 /cloudflare
sudo chmod 600 /cloudflare/.env
sudo chmod 700  /cloudflare/update_dns_cloudflare.sh
sudo -u ddnsuser bash /cloudflare/update_dns_cloudflare.sh midominio.cl www
echo "* * * * * bash /cloudflare/update_dns_cloudflare.sh midominio.cl www > /cloudflare/ddns_cloudflare.log 2>&1" | sudo crontab -u ddnsuser -
