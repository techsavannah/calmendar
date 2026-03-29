class GroupMembership < ApplicationRecord
  ROLES = %w[member organizer].freeze

  belongs_to :group
  belongs_to :user

  validates :role, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :group_id }
end
