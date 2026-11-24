# frozen_string_literal: true

# Doorkeeper's PKCE migration (`rails generate doorkeeper:pkce`). force_pkce in
# config/initializers/doorkeeper.rb needs these columns to bind an
# authorization code to its code_challenge; without them doorkeeper 5.9.10
# refuses the authorization code flow for public clients.
class EnablePkce < ActiveRecord::Migration[8.1]
  def change
    add_column :oauth_access_grants, :code_challenge, :string, null: true
    add_column :oauth_access_grants, :code_challenge_method, :string, null: true
  end
end
