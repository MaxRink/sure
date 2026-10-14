class Current < ActiveSupport::CurrentAttributes
  attribute :user_agent, :ip_address

  attribute :session
  attribute :latest_sync_by_syncable, :latest_completed_sync_by_syncable, :syncing_by_syncable

  # `user.family` is the immutable home family for backwards compatibility.
  # Requests may select another family only after membership authorization.
  def family
    active_family || user&.family
  end

  def active_family
    return @active_family if defined?(@active_family)
    return @active_family = nil unless user

    family_id = @requested_family_id || session&.data&.[]("active_family_id")
    @active_family = if family_id.present?
      candidate = Family.find_by(id: family_id)
      candidate if candidate && user.member_of?(candidate)
    end
  end

  def select_family!(candidate)
    raise ArgumentError, "user is not a member of this family" unless user&.member_of?(candidate)

    @requested_family_id = candidate.id
    @active_family = candidate
    if session&.persisted?
      session.data = (session.data || {}).merge("active_family_id" => candidate.id)
      session.save!
    end
    candidate
  end

  def clear_selected_family!
    @requested_family_id = nil
    @active_family = nil
    if session&.persisted?
      session.data = (session.data || {}).except("active_family_id")
      session.save!
    end
  end

  def user
    impersonated_user || session&.user
  end

  def impersonated_user
    session&.active_impersonator_session&.impersonated
  end

  def true_user
    session&.user
  end

  def accessible_accounts
    return family&.accounts unless user
    user.accessible_accounts
  end

  def finance_accounts
    return family&.accounts unless user
    user.finance_accounts
  end

  def accessible_entries
    return family&.entries unless user
    family.entries.joins(:account).merge(Account.accessible_by(user))
  end

  # Used for invalidating caches whose results depend on the current user's
  # account-share access (e.g. the transactions index's uncategorized count
  # and projected recurring list, which are scoped to accessible accounts).
  # Changes whenever an AccountShare granting/revoking the user's access is
  # created, updated, or destroyed.
  def account_share_version
    return "0-" unless user
    shares = AccountShare.where(user: user)
    "#{shares.count}-#{shares.maximum(:updated_at)&.to_f}"
  end
end
