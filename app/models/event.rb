class Event < ApplicationRecord
  belongs_to :group
  has_many :event_rsvps, dependent: :destroy
  has_many :rsvpers, through: :event_rsvps, source: :user

  STATUSES = %w[draft published canceled].freeze
  VISIBILITIES = %w[public private].freeze

  validates :title, presence: true
  validates :starts_at, presence: true
  validates :ends_at, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :visibility, inclusion: { in: VISIBILITIES }
  validate :ends_at_after_starts_at

  scope :published,         -> { where(status: "published") }
  scope :draft,             -> { where(status: "draft") }
  scope :canceled,          -> { where(status: "canceled") }
  scope :public_visibility, -> { where(visibility: "public") }
  scope :upcoming,          -> { where("starts_at >= ?", Time.current) }

  def rsvp_open?
    return false unless status == "published"
    return false if rsvp_opens_at.present? && rsvp_opens_at > Time.current
    return false if rsvp_closes_at.present? && rsvp_closes_at <= Time.current
    true
  end

  def rsvp_full?
    rsvp_limit.present? && event_rsvps.count >= rsvp_limit
  end

  def rsvped_by?(user)
    return false if user.nil?
    event_rsvps.exists?(user: user)
  end

  private

  def ends_at_after_starts_at
    return unless starts_at.present? && ends_at.present?
    errors.add(:ends_at, "must be after start time") if ends_at <= starts_at
  end
end
