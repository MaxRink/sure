# frozen_string_literal: true

require "uri"

module Sure
  module TestDatabaseSafety
    PRODUCTION_NAMES = %w[sure_production production sure_development].freeze
    LIVE_HOSTS = %w[db sure-db-1].freeze

    module_function

    def test_requested?(argv: ARGV, env: ENV)
      return true if env["RAILS_ENV"] == "test"

      argv.each_with_index.any? do |argument, index|
        argument == "test" || argument.start_with?("db:test:") || argument == "--environment=test" || (argument == "-e" && argv[index + 1] == "test")
      end
    end

    def validate!(argv: ARGV, env: ENV)
      return unless test_requested?(argv: argv, env: env)

      url = env["SURE_TEST_DATABASE_URL"].to_s
      name = env["SURE_TEST_DB_NAME"].to_s
      abort "Refusing test boot: SURE_TEST_DATABASE_URL is required" if url.empty?
      abort "Refusing test boot: SURE_TEST_DB_NAME is required" if name.empty?
      abort "Refusing test boot: test database name is not isolated" if PRODUCTION_NAMES.include?(name)

      parsed = URI.parse(url)
      host = parsed.host.to_s
      database = parsed.path.to_s.sub(%r{\A/}, "")
      abort "Refusing test boot: test database name must identify a test database" unless name.match?(/test/i)
      abort "Refusing test boot: test database URL must use PostgreSQL" unless %w[postgres postgres+tcp postgresql].include?(parsed.scheme)
      abort "Refusing test boot: test database URL must use a local disposable host" unless %w[127.0.0.1 ::1 localhost].include?(host)
      abort "Refusing test boot: test database URL points at a live host" if LIVE_HOSTS.include?(host)
      abort "Refusing test boot: database URL/name mismatch" unless database == name
      abort "Refusing test boot: inherited production database settings are present" if env["POSTGRES_DB"].to_s != "" || env["DATABASE_URL"].to_s != ""
      env["RAILS_ENV"] = "test"
    rescue URI::InvalidURIError
      abort "Refusing test boot: invalid SURE_TEST_DATABASE_URL"
    end
  end
end
