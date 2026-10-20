#!/usr/bin/env bash
# PokeIdle LXC - Chromium via web (KasmVNC) abrindo pokeidle.io
set -euo pipefail

# ===== Configuração =====
URL="https://pokeidle.io"
HOSTNAME="pokeidle"
CORES=2
RAM=2048
DISK=8
BRIDGE="vmbr0"
WEB_USER="niel"
WEB_PASS="$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 12)"
TZ="America/Fortaleza"
# ========================

CTID="$(pvesh get /cluster/nextid)"
STORAGE="$(pvesm status -content rootdir | awk 'NR>1 {print $1; exit}')"
TSTORAGE="$(pvesm status -content vztmpl | awk 'NR>1 {print $1; exit}')"

echo ">> Atualizando templates..."
pveam update >/dev/null
TEMPLATE="$(pveam available --section system | awk '/debian-12-standard/ {print $2}' | sort -V | tail -1)"
if ! pveam list "$TSTORAGE" | grep -q "$TEMPLATE"; then
  echo ">> Baixando $TEMPLATE..."
  pveam download "$TSTORAGE" "$TEMPLATE"
fi

echo ">> Criando LXC $CTID..."
pct create "$CTID" "$TSTORAGE:vztmpl/$TEMPLATE" \
  --hostname "$HOSTNAME" \
  --cores "$CORES" --memory "$RAM" --swap 512 \
  --rootfs "$STORAGE:$DISK" \
  --net0 name=eth0,bridge="$BRIDGE",ip=dhcp \
  --features nesting=1,keyctl=1 \
  --unprivileged 1 --onboot 1 \
  --password "$WEB_PASS"

pct start "$CTID"

echo ">> Aguardando rede..."
for i in $(seq 1 30); do
  pct exec "$CTID" -- ping -c1 -W1 1.1.1.1 >/dev/null 2>&1 && break
  sleep 2
done

echo ">> Instalando Docker..."
pct exec "$CTID" -- bash -c "apt-get update -qq && apt-get install -y -qq curl ca-certificates && curl -fsSL https://get.docker.com | sh"

echo ">> Criando compose..."
cat > /tmp/pokeidle-compose.yml <<EOF
services:
  chromium:
    image: lscr.io/linuxserver/chromium:latest
    container_name: pokeidle
    security_opt:
      - seccomp:unconfined
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=${TZ}
      - CHROME_CLI=${URL}
      - CUSTOM_USER=${WEB_USER}
      - PASSWORD=${WEB_PASS}
    volumes:
      - ./config:/config
    ports:
      - 3000:3000
      - 3001:3001
    shm_size: "1gb"
    restart: unless-stopped
EOF

pct exec "$CTID" -- mkdir -p /opt/pokeidle
pct push "$CTID" /tmp/pokeidle-compose.yml /opt/pokeidle/docker-compose.yml
rm -f /tmp/pokeidle-compose.yml

echo ">> Subindo container..."
pct exec "$CTID" -- bash -c "cd /opt/pokeidle && docker compose up -d"

IP="$(pct exec "$CTID" -- hostname -I | awk '{print $1}')"
echo
echo "=============================================="
echo " PokeIdle pronto!"
echo " Acesse:  https://${IP}:3001"
echo " Usuário: ${WEB_USER}"
echo " Senha:   ${WEB_PASS}  (também é a senha root do LXC)"
echo " CTID:    ${CTID}"
echo "=============================================="
