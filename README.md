# LXC-PROXMOX-Debian-Browser
LXC no proxmox abrindo somente um navegador para rodar pokeidle

O script escolhe sozinho o storage e a próxima ID livre. Se você usa outra bridge que não vmbr0, ajuste a variável BRIDGE.
A senha é gerada aleatoriamente e mostrada no final. Anote.
O certificado do :3001 é autoassinado, então o navegador vai avisar. É normal.
O perfil do navegador (incluindo o save do jogo) fica em /opt/pokeidle/config dentro do LXC. Vale incluir esse LXC no backup do Proxmox.
Se o Docker reclamar de permissão ou AppArmor ao subir (acontece em algumas versões do Proxmox), me manda o erro que eu te passo o ajuste na config do LXC.

Comando (utilize o shell do proxmox): 
bash -c "$(curl -fsSL https://raw.githubusercontent.com/NielDayzEclipse/LXC-PROXMOX-Debian-Browser/main/pokeidle.sh)" 

---

## Claude Code + Proxmox MCP

Script para criar um LXC com o Claude Code conectado à API do Proxmox. Veja [claude-mcp/README.md](claude-mcp/README.md).

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/NielDayzEclipse/LXC-PROXMOX-Debian-Browser/main/claude-mcp/claude-proxmox-lxc.sh)"
```
