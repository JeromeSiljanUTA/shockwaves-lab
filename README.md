# Shockwave's Lab

This is where I will keep the configuration of all the containers running on NEMESIS.

## Management

A `Makefile` wraps the per-service compose projects. Run `make` (or `make help`) from the repo root.

```bash
make list              # show discovered services
make pull              # pull all images
make up                # start everything
make upgrade           # pull + up, all services
make ps                # status
make logs              # recent logs (all)
make config            # validate all compose files
```

Append `SERVICE=<dir>` to act on one service:

```bash
make upgrade SERVICE=immich-app
make logs SERVICE=gitea
```

Docker is invoked as `sudo docker` by default; override with `make DOCKER=docker ...`.
