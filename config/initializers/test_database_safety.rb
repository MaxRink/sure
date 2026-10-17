# frozen_string_literal: true

if ENV["RAILS_ENV"] == "test" && !ARGV.include?("db:create")
  expected = ENV.fetch("SURE_TEST_DB_NAME")
  actual = ActiveRecord::Base.connection.select_value("SELECT current_database()")
  abort "Refusing test boot: connected database does not match isolated test database" unless actual == expected
end
