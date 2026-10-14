# frozen_string_literal: true

require "test_helper"

class AccountPolicyTest < ActiveSupport::TestCase
  setup do
    @user = users(:family_admin)
    @home = @user.family
    @other = families(:empty)
    @account = Account.new(family: @other)
  end

  test "home admin is not an admin in a guest or member family context" do
    membership = @user.family_memberships.find_or_initialize_by(family: @other)
    membership.update!(role: "guest")
    assert_not AccountPolicy.new(@user, @account).create?

    membership.update!(role: "member")
    assert_not AccountPolicy.new(@user, @account).create?
  end

  test "a family admin may create accounts in that family" do
    @user.family_memberships.find_or_initialize_by(family: @other).update!(role: "admin")
    assert AccountPolicy.new(@user, @account).create?
  end
end
