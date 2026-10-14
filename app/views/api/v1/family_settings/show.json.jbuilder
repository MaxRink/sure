# frozen_string_literal: true

json.id @family.id
json.name @family.name
json.currency @family.currency
json.locale @family.locale
json.date_format @family.date_format
json.country @family.country
json.timezone @family.timezone
json.month_start_day @family.month_start_day
json.moniker @family.moniker
json.default_account_sharing @family.default_account_sharing
json.custom_enabled_currencies @family.custom_enabled_currencies?
json.enabled_currencies @family.enabled_currency_codes
json.created_at @family.created_at.iso8601
json.updated_at @family.updated_at.iso8601
json.active true
json.memberships do
  json.array! Current.user.families.order(:id) do |family|
    json.id family.id
    json.name family.name
    json.home Current.user.family_id == family.id
    json.role Current.user.membership_for(family)&.role
  end
end
