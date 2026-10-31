# jeromesiljan.com

The blog site, the first_time_guest API, nginx, and a Cloudflare tunnel. The
blog is static output served by nginx; the API image is
`git.nemesis.home.arpa/jerome/first-time-guest`.

Deploy config lives here (like every other Shockwave's Lab service); the blog
and first_time_guest repos build and publish, then call the shared deploy
wrapper.

Runtime files on the host:

```
/iacon/containers/volumes/jeromesiljan-com/nginx/nginx.conf
/iacon/containers/volumes/jeromesiljan-com/nginx/logs/
/iacon/containers/volumes/jeromesiljan-com/blog/          # built by the blog pipeline
/iacon/containers/volumes/secrets/jeromesiljan-com/nginx/.htpasswd
/iacon/containers/volumes/secrets/jeromesiljan-com/nginx/.htpasswd-occ
/iacon/containers/volumes/secrets/jeromesiljan-com/cloudflared/
/iacon/containers/volumes/secrets/jeromesiljan-com/secrets.env
```

Non-secret config is in `config.env`.
