# Shockwave's Lab

Docker container setup for **NEMESIS**. One directory per service, each with its own `docker-compose.yml`.

The host config (Docker, nginx, firewall, DNS, etc.) lives in the **nixos** repo: `hosts/NEMESIS/configuration.nix`.

## Nginx

Every service gets an nginx virtual host in the nixos repo so it has a clean name instead of a port:

```
service.nemesis.home.arpa  ->  http://127.0.0.1:<port>
```

`*.nemesis.home.arpa` resolves to NEMESIS via dnsmasq on MIRAGE. Add a vhost there for each new service.

## Volumes

Persistent state lives in a sibling `../volumes/<service>/` directory, bind-mounted into the container. Nothing in `volumes/` is tracked here — only the compose files are.

```yaml
volumes:
  - ../../volumes/jellyfin/config:/config
  - ../../volumes/jellyfin/media:/media
```

## Secrets

Credentials live in `../volumes/secrets/<service>/secrets.env` and are loaded with `env_file`. Never committed.

```yaml
env_file:
  - ../../volumes/secrets/immich-app/secrets.env
```

For values that only affect one container, `environment:` may still reference vars from that env file:

```yaml
environment:
  POSTGRES_USER: ${DB_USERNAME}
  POSTGRES_DB: ${DB_DATABASE_NAME}
```
