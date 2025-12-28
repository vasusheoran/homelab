VM igpu passthrough #https://github.com/LongQT-sea/intel-igpu-passthru?tab=readme-ov-file#overview

# https://github.com/LongQT-sea/pve-qemu-builder/releases
curl -OL https://github.com/LongQT-sea/pve-qemu-builder/releases/download/v10.1.2-4/pve-qemu-kvm_10.1.2-4_amd64.deb
apt install -y ./pve-qemu-kvm_10.1.2-4_amd64.deb


curl -L "https://release-assets.githubusercontent.com/github-production-release-asset/1064724358/d9cf4c55-6fa2-4f70-8e10-043b8582f011?sp=r&sv=2018-11-09&sr=b&spr=https&se=2025-12-20T14%3A14%3A34Z&rscd=attachment%3B+filename%3DRKL_TGL_ADL_RPL_GOPv17.1_igd.rom&rsct=application%2Foctet-stream&skoid=96c2d410-5711-43a1-aedd-ab1947aa7ab0&sktid=398a6654-997b-47e9-b12b-9515b896b4de&skt=2025-12-20T13%3A14%3A06Z&ske=2025-12-20T14%3A14%3A34Z&sks=b&skv=2018-11-09&sig=d5gHrTi7YGtS1io4fw3dv3oGEaTCwBRSESYASmSTA%2Bk%3D&jwt=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmVsZWFzZS1hc3NldHMuZ2l0aHVidXNlcmNvbnRlbnQuY29tIiwia2V5Ijoia2V5MSIsImV4cCI6MTc2NjIzNzAxNSwibmJmIjoxNzY2MjM2NzE1LCJwYXRoIjoicmVsZWFzZWFzc2V0cHJvZHVjdGlvbi5ibG9iLmNvcmUud2luZG93cy5uZXQifQ.WjDUfUy81GCaOJk50prI-HjNaCTCHAY1oqsKlQvC8nk&response-content-disposition=attachment%3B%20filename%3DRKL_TGL_ADL_RPL_GOPv17.1_igd.rom&response-content-type=application%2Foctet-stream" -o /usr/share/kvm/igd.rom


qm set 202 --machine pc \
              --vga none \
              --bios ovmf \
              --hostpci0 0000:00:02.0,legacy-igd=1,romfile=igd.rom



qm set 202 --machine q35 \
--bios ovmf \
--hostpci0 0000:00:02.0,romfile=igd.rom \
--args "-set device.hostpci0.bus=pci.0 -set device.hostpci0.addr=2.0 -set device.hostpci0.x-igd-opregion=on"


# Do not commit



dd bs=1M conv=fdatasync if=/var/lib/vz/template/iso/proxmox-ve_*.iso of=/dev/sdc1



sudo nmcli connection modify "Wired Connection 1" \
ipv4.method "manual" \
ipv4.addresses "192.168.1.100/24" \
ipv4.gateway "192.168.1.1" \
ipv4.dns "8.8.8.8,8.8.4.4"











  
  
  
  
  
  
  
  
  
  
  
  { "host": "pihole", "id": "151", "ip": "192.168.1.151", "port": 80 , "type": "lxc", "url": "http://192.168.1.151:80", "domain": "https://pihole.kuchbhi92.duckdns.org", data: {} },
  { "host": "jellyfin", "id": "154", "ip": "192.168.1.154", "port": 8096 , "type": "lxc", "url": "http://192.168.1.154:8096", "domain": "https://jellyfin.kuchbhi92.duckdns.org", data: {} },
  { "host": "nginx", "id": "155", "ip": "192.168.1.155", "port": 81 , "type": "lxc", "url": "http://192.168.1.155:81", "domain": "https://nginx.kuchbhi92.duckdns.org", data: {} },
  { "host": "immich", "id": "157", "ip": "192.168.1.157", "port": 2283 , "type": "lxc", "url": "http://192.168.1.157:2283", "domain": "https://immich.kuchbhi92.duckdns.org", data: {} },
  { "host": "homepage", "id": "159", "ip": "192.168.1.159", "port": 3000 , "type": "lxc", "url": "http://192.168.1.159:3000", "domain": "https://homepage.kuchbhi92.duckdns.org", data: {} },
  { "host": "jellyseer", "id": "163", "ip": "192.168.1.163", "port": 5055 , "type": "lxc", "url": "http://192.168.1.163:5055", "domain": "https://jellyseer.kuchbhi92.duckdns.org", data: {} },
  { "host": "beszel", "id": "168", "ip": "192.168.1.168", "port": 8090 , "type": "lxc", "url": "http://192.168.1.168:8090", "domain": "https://beszel.kuchbhi92.duckdns.org", data: {} },
  { "host": "n8n", "id": "172", "ip": "192.168.1.172", "port": 5678 , "type": "lxc", "url": "http://192.168.1.172:5678", "domain": "", data: {} },
  { "host": "tailscale", "id": "200",  "type": "lxc", "url": "", "domain": "", data: {} },
  { "host": "dockage", "id": "165", "ip": "192.168.1.165", "port": 5001 , "type": "lxc", "url": "http://192.168.1.165:5001", "domain": "https://dockge.kuchbhi92.duckdns.org", data: {} },
  { "host": "radarr", "id": "165", "ip": "192.168.1.165", "port": 7878 , "type": "docker", "url": "http://192.168.1.165:7878", "domain": "https://radarr.kuchbhi92.duckdns.org", data: {} },
  { "host": "sonarr", "id": "165", "ip": "192.168.1.165", "port": 8989 , "type": "docker", "url": "http://192.168.1.165:8989", "domain": "https://sonarr.kuchbhi92.duckdns.org", data: {} },
  { "host": "prowlarr", "id": "165", "ip": "": "https://prowlarr", "port": kuchbhi92 , "type": "docker", "url": "", "domain": "https://prowlarr.kuchbhi92.duckdns.org", data: {} },
  { "host": "bazarr", "id": "165", "ip": "192.168.1.165", "port": 6767 , "type": "docker", "url": "http://192.168.1.165:6767", "domain": "https://bazarr.kuchbhi92.duckdns.org", data: {} },
  { "host": "gluetun", "id": "165", "ip": "192.168.1.165", "port": 9999 , "type": "docker", "url": "http://192.168.1.165:9999", "domain": "", data: {} },
  { "host": "qbittorrent", "id": "165", "ip": "192.168.1.165", "port": 8080 , "type": "docker", "url": "http://192.168.1.165:8080", "domain": "https://qbittorrent.kuchbhi92.duckdns.org", data: {} },
  { "host": "trends", "id": "165", "ip": "192.168.1.165", "port": 5000 , "type": "docker", "url": "http://192.168.1.165:5000", "domain": "https://trends.kuchbhi92.duckdns.org", data: {} },
  { "host": "truenas", "id": "as", "ip": "192.168.1.6", "port": 80 , "type": "vm", "url": "http://192.168.1.6", "domain": "https://nas.kuchbhi92.duckdns.org", data: {} },


-d "{\"identity\": \"admin@homelab.com\", \"secret\": \"usav@321\"}" 
  

  curl "http://192.168.0.100/api/tokens"   -H "Content-Type: application/json; charset=UTF-8"   --data-raw '{"identity":"admin@homelab.com","secret":"usav@321","expiry":"1y"}'