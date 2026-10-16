require "test_helper"

class FamilyMembershipTest < ActiveSupport::TestCase
  setup do
    @user = users(:family_member)
    @home = @user.family
    @other = families(:empty)
    @user.family_memberships.find_or_create_by!(family: @home, role: "member")
  end

  test "a user can select a second family without changing home ownership" do
    membership = @user.family_memberships.create!(family: @other, role: "admin")
    session = @user.sessions.build(data: {})
    Current.session = session

    Current.select_family!(@other)

    assert_equal @other, Current.family
    assert_equal @home.id, @user.reload.family_id
    assert_equal membership.family_id, @user.membership_for(@other).family_id
  end

  test "a user cannot select a family where they are not a member" do
    outsider_family = Family.create!(name: "Outsider test family", currency: "USD")
    Current.session = @user.sessions.build(data: {})

    assert_raises(ArgumentError) { Current.select_family!(outsider_family) }
    assert_equal @home, Current.family
  end

  test "the active family is persisted only on an existing web session" do
    @user.family_memberships.create!(family: @other, role: "member")
    session = @user.sessions.create!(data: {})
    Current.session = session

    Current.select_family!(@other)

    assert_equal @other.id.to_s, session.reload.data["active_family_id"].to_s
  end

  test "family role checks do not use the user's home role" do
    @user.update!(role: "admin")
    @user.family_memberships.find_by!(family: @home).update!(role: "admin")
    @user.family_memberships.create!(family: @other, role: "member")

    assert @user.admin_for?(@home)
    assert_not @user.admin_for?(@other)
    assert @user.member_for?(@other)

    @user.membership_for(@other).update!(role: "guest")
    assert_not @user.member_for?(@other)
    assert_not @user.admin_for?(@other)
  end

  test "selecting a family never changes the home role or family" do
    @user.update!(role: "admin")
    @user.family_memberships.create!(family: @other, role: "guest")
    Current.session = @user.sessions.build(data: {})

    Current.select_family!(@other)

    assert_equal @home.id, @user.reload.family_id
    assert_equal "admin", @user.role
    assert_equal "guest", @user.membership_for(@other).role
  end
end
