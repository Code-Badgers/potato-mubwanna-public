#!/usr/bin/env bash

set -euo pipefail

deploy_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
public_domain="$(sed -n 's/^PUBLIC_DOMAIN=//p' "${deploy_dir}/.env.example" | tail -n 1)"

MSYS_NO_PATHCONV=1 docker run --rm \
  --env "PUBLIC_DOMAIN=${public_domain}" \
  --mount "type=bind,source=${deploy_dir}/caddy/Caddyfile,target=/etc/caddy/Caddyfile,readonly" \
  caddy:2.11.4-alpine \
  caddy validate --config /etc/caddy/Caddyfile

echo "Caddy production configuration is valid."
