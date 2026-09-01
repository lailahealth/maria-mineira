# Maria Mineira

## Development environment

This app runs fully containerized — no local Ruby, Postgres, or PostGIS
install required. Both options below build the same image
(`.devcontainer/Dockerfile`: Ruby 3.4.8 + libvips + psql) against the same
Postgres 17 + PostGIS 3.5 database config, so pick whichever fits your editor.

### Option A: plain `docker compose up`

```
docker compose up
```

First run installs gems (cached in the `bundle-cache` volume for next time),
prepares the database (`primary` + `analytics`), and starts `bin/dev`
(server + Tailwind watcher) at `http://localhost:3000`. Postgres is also
published on `localhost:5432` if you want to connect a client directly.

### Option B: VS Code Dev Containers

1. Install [Docker](https://www.docker.com/) and the
   [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
   (or the [CLI](https://github.com/devcontainers/cli)).
2. Open the project folder in VS Code and choose "Reopen in Container" (or
   run `devcontainer up`).
3. The container runs `bin/setup --skip-server` on creation, which installs
   gems and prepares the database.
4. Start the app with `bin/dev` inside the container terminal.

Each option keeps the Postgres data in its own Docker volume, so they don't
share data with each other or with anything installed on your machine.
