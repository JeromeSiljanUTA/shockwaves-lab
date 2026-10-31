# Vector Prime

Backend API + scheduler. Images are built with Nix in the
[vector-prime](http://git.nemesis.home.arpa/jerome/vector-prime) repo and pushed
to the Gitea container registry; this directory is deploy config only.

```
image: git.nemesis.home.arpa/jerome/vector-prime-api:latest
```

vector-prime's Woodpecker pipeline builds and pushes the images, then triggers
the normal deploy (`make upgrade SERVICE=vector-prime`) through the shared
`/run/woodpecker/docker-deploy` wrapper. Nothing special is needed here beyond
the registry image names.

Secrets live at `../../volumes/secrets/vector-prime/secrets.env`; copy
`secrets.example.env` there and fill it in. Non-secret config is in
`config.env`.
