#!/bin/zsh

# Map each service to its compose file
# Format: service_to_file[service]=composefile
typeset -A service_to_file
service_to_file=(
  samba media/docker-compose.yaml
  jellyfin media/docker-compose.yaml
  jellyseer media/docker-compose.yaml
  prometheus dashboards/docker-compose.yaml
  node-exporter dashboards/docker-compose.yaml
  grafana dashboards/docker-compose.yaml
  cadvisor dashboards/docker-compose.yaml
  qbittorrent qBitTorrent/docker-compose.yaml
  gluetun arr/docker-compose.yaml
  prowlarr arr/docker-compose.yaml
  radarr arr/docker-compose.yaml
  sonarr arr/docker-compose.yaml
  bazarr arr/docker-compose.yaml
  homepage homepage/docker-compose.yaml
  nginx nginx/docker-compose.yaml
  portainer portainer/docker-compose.yaml
  trends trends/docker-compose.yaml
  trends-v2 trends/docker-compose.yaml
)

# Define your groups here
media=(samba jellyfin jellyseer)
dashboard=(prometheus node-exporter grafana cadvisor)
arr=(prowlarr radarr sonarr bazarr)
homepage=(homepage)
nginx=(nginx)
portainer=(portainer)
trends=(trends trends-v2)
common=(jellyfin prowlarr radarr sonarr bazarr nginx)

# Usage: ./service-groups.sh <groupname> <action>
group="$1"
action="$2"

if [[ -z "$group" || -z "$action" ]]; then
  echo "Usage: $0 <groupname> <action>"
  echo "Example: $0 media_services restart"
  exit 1
fi

# Get the array of services for the group
services=("${(@P)group}")
if [[ -z "$services" ]]; then
  echo "Group '$group' not found."
  exit 1
fi

# Build a mapping of compose files to their services
typeset -A file_services
for svc in "${services[@]}"; do
  file="${service_to_file[$svc]}"
  if [[ -z "$file" ]]; then
    echo "Service '$svc' does not have a compose file mapping."
    continue
  fi
  file_services[$file]+="$svc "
done

# Run docker compose for each file with its services
for file in "${(@k)file_services}"; do
  svcs=(${(s: :)file_services[$file]})
  echo "Running 'docker compose -f $file $action' for: ${svcs[@]}"
  docker compose -f "$file" $action ${svcs[@]}
done