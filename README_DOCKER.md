# Local dev stack: Rails + standalone MySQL + standalone Solr + MiniStack S3

This mirrors production (MySQL, Solr, S3-compatible object storage) using
single-node containers, so no need for a MySQL cluster, SolrCloud, or real Ceph
locally.

Ruby 3.3, Rails 8.0, built on Ubuntu 22.04 (Ruby is compiled from source via
`ruby-install`, since there's no official Ubuntu-based Ruby image — override the
version with `--build-arg RUBY_VERSION=3.3.x` if needed).

## Files

| File                                | Purpose                                                          |
|--------------------------------------|--------------------------------------------------------------------|
| `Dockerfile`                         | Builds the Rails app image                                         |
| `docker-compose.yml`                 | Wires up `web`, `db` (MySQL), `solr`, `redis`, and `ministack` (S3) |
| `docker/entrypoint.sh`               | Waits for MySQL + Solr before booting Rails                        |

## Running it

```bash
DOCKER_BUILDKIT=1 docker compose build --ssh default=${SSH_AUTH_SOCK}
docker compose run --rm web bin/rails db:migrate
docker compose up
```

App: http://localhost:3000
Solr admin: http://localhost:8983/solr
MiniStack: http://localhost:4566 (health check: `curl http://localhost:4566/_ministack/health`)

