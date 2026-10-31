# Shockwave's Lab

| ![Shockwave in his lab](shockwave-in-his-lab.jpg) | ![Shockwave's offsite laboratory](shockwaves-lab-wide.jpg) |
|:--:|:--:|
| Shockwave in his offsite laboratory | Rows of Predacon cloning pods |

<sub>Screenshots from *Transformers: Prime*.</sub>

Docker container setup for **NEMESIS**. One directory per service, each with its own `docker-compose.yml`.

The host config (Docker, nginx, firewall, DNS, etc.) lives in the **nixos** repo: `hosts/NEMESIS/configuration.nix`.

## Nginx

Every service gets an nginx virtual host in the nixos repo so it has a clean name instead of a port:

```
service.nemesis.home.arpa  ->  http://127.0.0.1:<port>
```

`*.nemesis.home.arpa` resolves to NEMESIS via dnsmasq on MIRAGE. Add a vhost there for each new service.

## F-Droid uploads

Three services cooperate:

- **`fdroid`** (`austozi/fdroidserver`) builds and signs the repo index on a
  timer, ingesting APKs from `volumes/fdroid/updates` via
  `fdroid/update-scripts/` into `volumes/fdroid/repo`.
- **`webserver`** (nginx) serves `volumes/fdroid/repo` on port `8090`.
- **`upload`** (miniserve) accepts APK uploads into `volumes/fdroid/updates`.

Upload (no auth by default):

```
curl -F "path=@app.apk" \
  http://fdroid.nemesis.home.arpa/upload/upload?path=/
```

To require basic auth, add `MINISERVE_AUTH=ci:<password>` to the `upload`
service's environment (e.g. via an `env_file`); miniserve reads that variable
natively.

APKs named `<anything>.apk` are ingested into the repo. A file named
`<package-id>_icon.png` is installed as the app icon at
`repo/<package-id>/en-US/icon.png` — needed because modern AGP obfuscates
`res/`, so fdroidserver cannot pull the launcher icon out of the APK itself.

nginx on NEMESIS maps `/upload/` → `127.0.0.1:8091` and `/fdroid/repo/` →
`127.0.0.1:8090`.

`vector-prime`'s `make mobile-push` performs the upload; `MOBILE_PUSH_WAIT=600`
polls the repo index until the rebuild lands.

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

## CI

Woodpecker watches this repo. On push to `master`, it detects the changed
service directories and runs, for each one:

```
make upgrade SERVICE=<service>
```

`make upgrade` pulls the latest images and recreates the service (`docker
compose pull` + `down` + `up -d`), so both image updates and edits to a
`docker-compose.yml` actually take effect — plain `compose restart` re-reads
neither.

The pipeline runs as the unprivileged `woodpecker` user. It first syncs the
pushed checkout into the deploy directory, then invokes a single root-owned
wrapper (`/run/woodpecker/docker-deploy`) via sudo. That wrapper takes **no
arguments** and only runs `make upgrade` for validated service names, so the CI
user never gets arbitrary docker or root access.

### Deploy location

The repo is deployed to **`/iacon/containers/shockwaves-lab`**. This is not
arbitrary: every compose file bind-mounts `../../volumes/...`, which resolves to
`/iacon/containers/volumes` only from this path. Running the compose files from
any other directory points the mounts at the wrong place.
