class FamilyMembership < ApplicationRecord
  ROLES = %w[admin member guest].freeze

  belongs_to :user
  belongs_to :family

  validates :role, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :family_id }

  def admin?
    role == "admin"
  end
end
