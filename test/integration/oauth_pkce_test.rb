# frozen_string_literal: true

require "test_helper"

# force_pkce with the PKCE columns: public clients (MCP dynamic registration,
# native apps) must bind every authorization code to an S256 challenge, and
# confidential clients keep the plain authorization code flow.
class OauthPkceTest < ActionDispatch::IntegrationTest
  REDIRECT_URI = "https://client.example.com/callback"

  setup do
    @user = users(:family_admin)
    @public_app = Doorkeeper::Application.create!(
      name: "PKCE Public Client #{SecureRandom.hex(4)}",
      redirect_uri: REDIRECT_URI,
      confidential: false,
      scopes: "read_write"
    )
    @verifier = SecureRandom.urlsafe_base64(64)
    @challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(@verifier), padding: false)
  end

  test "access grants store the PKCE challenge" do
    assert Doorkeeper.config.force_pkce?
    assert Doorkeeper::AccessGrant.pkce_supported?, "oauth_access_grants needs code_challenge and code_challenge_method"
    assert_equal %w[S256], Doorkeeper.config.pkce_code_challenge_methods_supported
  end

  test "public client without code_challenge gets no authorization code" do
    sign_in(@user)

    assert_no_difference("Doorkeeper::AccessGrant.count") do
      post "/oauth/authorize", params: authorize_params
    end

    assert_response :redirect
    query = redirect_query
    assert_nil query["code"]
    assert_equal "invalid_request", query["error"]
  end

  test "public client with a plain code_challenge gets no authorization code" do
    sign_in(@user)

    assert_no_difference("Doorkeeper::AccessGrant.count") do
      post "/oauth/authorize", params: authorize_params(code_challenge: @verifier, code_challenge_method: "plain")
    end

    assert_response :redirect
    query = redirect_query
    assert_nil query["code"]
    assert_equal "invalid_code_challenge_method", query["error"]
  end

  test "public client with S256 gets a code bound to the challenge and a token for the verifier" do
    sign_in(@user)

    post "/oauth/authorize", params: authorize_params(code_challenge: @challenge, code_challenge_method: "S256")

    assert_response :redirect
    code = redirect_query["code"]
    assert code.present?, "Authorization response should contain a code"

    grant = Doorkeeper::AccessGrant.where(application: @public_app).order(:created_at).last
    assert_equal @challenge, grant.code_challenge
    assert_equal "S256", grant.code_challenge_method

    post "/oauth/token", params: token_params(code, code_verifier: @verifier)

    assert_response :success
    assert JSON.parse(response.body)["access_token"].present?
  end

  test "public client code cannot be exchanged without the verifier or with a wrong one" do
    sign_in(@user)
    post "/oauth/authorize", params: authorize_params(code_challenge: @challenge, code_challenge_method: "S256")
    code = redirect_query["code"]
    assert code.present?

    post "/oauth/token", params: token_params(code)
    assert_response :bad_request
    assert_equal "invalid_grant", JSON.parse(response.body)["error"]

    post "/oauth/token", params: token_params(code, code_verifier: SecureRandom.urlsafe_base64(64))
    assert_response :bad_request
    assert_equal "invalid_grant", JSON.parse(response.body)["error"]
  end

  test "confidential client still completes the authorization code flow without PKCE" do
    app = Doorkeeper::Application.create!(
      name: "Confidential Client #{SecureRandom.hex(4)}",
      redirect_uri: REDIRECT_URI,
      confidential: true,
      scopes: "read"
    )
    sign_in(@user)

    post "/oauth/authorize", params: {
      client_id: app.uid,
      redirect_uri: REDIRECT_URI,
      response_type: "code",
      scope: "read"
    }

    assert_response :redirect
    code = redirect_query["code"]
    assert code.present?, "Authorization response should contain a code"

    post "/oauth/token", params: {
      grant_type: "authorization_code",
      client_id: app.uid,
      client_secret: app.plaintext_secret,
      redirect_uri: REDIRECT_URI,
      code: code
    }

    assert_response :success
    assert JSON.parse(response.body)["access_token"].present?
  end

  test "public client cannot use the client credentials grant" do
    post "/oauth/token", params: {
      grant_type: "client_credentials",
      client_id: @public_app.uid
    }

    assert_includes [ 400, 401 ], response.status
    assert_nil JSON.parse(response.body)["access_token"]
  end

  private

    def authorize_params(**pkce)
      {
        client_id: @public_app.uid,
        redirect_uri: REDIRECT_URI,
        response_type: "code",
        scope: "read_write"
      }.merge(pkce)
    end

    def token_params(code, **extra)
      {
        grant_type: "authorization_code",
        client_id: @public_app.uid,
        redirect_uri: REDIRECT_URI,
        code: code
      }.merge(extra)
    end

    def redirect_query
      Rack::Utils.parse_query(URI.parse(response.location).query)
    end
end
