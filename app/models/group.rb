class Group < ApplicationRecord
  has_many :group_memberships, dependent: :destroy
  has_many :users, through: :group_memberships

  has_many :organizer_memberships,
           -> { where(role: "organizer") },
           class_name: "GroupMembership",
           dependent: false
  has_many :organizers, through: :organizer_memberships, source: :user

  has_many :member_memberships,
           -> { where(role: "member") },
           class_name: "GroupMembership",
           dependent: false
  has_many :members, through: :member_memberships, source: :user

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :description, length: { maximum: 1000 }

  # Returns true if the user has any membership in this group (member or organizer).
  def member?(user)
    group_memberships.exists?(user: user)
  end

  def organizer?(user)
    organizer_memberships.exists?(user: user)
  end
end
