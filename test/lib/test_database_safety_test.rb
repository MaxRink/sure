# frozen_string_literal: true

require "minitest/autorun"
require_relative "../../lib/sure/test_database_safety"

class TestDatabaseSafetyTest < Minitest::Test
  def base_env
    {
      "RAILS_ENV" => "test",
      "SURE_TEST_DATABASE_URL" => "postgresql://127.0.0.1:5432/sure_test_isolated",
      "SURE_TEST_DB_NAME" => "sure_test_isolated"
    }
  end

  def test_accepts_explicit_local_isolated_database
    Sure::TestDatabaseSafety.validate!(env: base_env, argv: [])
  end

  def test_rejects_inherited_production_database
    env = base_env.merge("POSTGRES_DB" => "sure_production")
    assert_raises(SystemExit) { Sure::TestDatabaseSafety.validate!(env: env, argv: []) }
  end

  def test_rejects_live_database_host
    env = base_env.merge("SURE_TEST_DATABASE_URL" => "postgresql://db:5432/sure_test_isolated")
    assert_raises(SystemExit) { Sure::TestDatabaseSafety.validate!(env: env, argv: []) }
  end

  def test_recognizes_test_tasks_before_rails_boot
    assert Sure::TestDatabaseSafety.test_requested?(argv: ["db:test:prepare"], env: {})
    assert Sure::TestDatabaseSafety.test_requested?(argv: ["test"], env: {})
  end

  def test_accepts_the_ci_workflow_environment
    env = {
      "RAILS_ENV" => "test",
      "SURE_TEST_DATABASE_URL" => "postgres://postgres:postgres@127.0.0.1:5432/sure_test_ci_unit",
      "SURE_TEST_DB_NAME" => "sure_test_ci_unit"
    }

    Sure::TestDatabaseSafety.validate!(env: env, argv: ["test"])
  end
end
