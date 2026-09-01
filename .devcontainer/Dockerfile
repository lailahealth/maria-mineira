# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.4.8
FROM ghcr.io/rails/devcontainer/images/ruby:$RUBY_VERSION

# libvips: Active Storage variants (image_processing gem). postgresql-client: psql.
# Baked in here (rather than left to devcontainer.json features) so a plain
# `docker compose build` gets the same image as the Dev Containers CLI does.
USER root
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y libvips postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives
USER vscode

# Ensure binding is always 0.0.0.0
# Binds the server to all IP addresses of the container, so it can be accessed from outside the container.
ENV BINDING="0.0.0.0"

# The base image manages Ruby via mise, activated in ~/.bashrc for interactive
# shells only. Put the shims (ruby/bundle/rails) and the mise binary itself
# (shims exec back into it) on PATH unconditionally, so non-interactive
# `docker compose run`/`command:` invocations (no login shell involved) work.
ENV PATH="/home/vscode/.local/share/mise/shims:/home/vscode/.local/bin:${PATH}"
