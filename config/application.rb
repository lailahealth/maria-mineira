require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module MariaMineira
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # PostGIS/tiger-geocoder extensions own dozens of their own tables (addr,
    # edges, topology.layer, spatial_ref_sys, ...). schema.rb's dumper can't
    # tell those apart from app tables and tries to `DROP TABLE ... CASCADE`
    # them on load, which Postgres refuses (they can only be dropped via
    # `DROP EXTENSION`). structure.sql (pg_dump) handles this correctly: it
    # just emits `CREATE EXTENSION` and lets Postgres bring in the extension's
    # own tables, so it's the standard approach for PostGIS-heavy Rails apps.
    config.active_record.schema_format = :sql

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
