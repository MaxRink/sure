require "test_helper"

class Settings::FamiliesControllerTest < ActionDispatch::IntegrationTest
  test "super admin can create a family space without moving home family" do
    user = users(:sure_support_staff)
    home_family_id = user.family_id

    sign_in user

    assert_difference([ "Family.count", "FamilyMembership.count" ], 1) do
      post settings_families_url, params: { family: { name: "WG Max Charlotte", moniker: "Group" } }
    end

    family = Family.find_by!(name: "WG Max Charlotte")
    assert_redirected_to settings_families_url
    assert_equal home_family_id, user.reload.family_id
    assert_equal "WG Max Charlotte", family.name
    assert user.reload.member_of?(family)
    assert user.reload.admin_for?(family)
  end

  test "non super admin cannot create a family space" do
    user = users(:family_admin)
    sign_in user

    assert_no_difference([ "Family.count", "FamilyMembership.count" ]) do
      post settings_families_url, params: { family: { name: "Unauthorized", moniker: "Group" } }
    end

    assert_redirected_to settings_families_url
  end
end
