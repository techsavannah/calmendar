class EventRsvp < ApplicationRecord
  belongs_to :event
  belongs_to :user

  validates :user_id, uniqueness: { scope: :event_id, message: "has already RSVPed to this event" }
  validate :event_must_accept_rsvps, on: :create

  private

  def event_must_accept_rsvps
    return unless event.present?
    unless event.rsvp_open?
      errors.add(:base, "RSVPs are not currently open for this event")
    end
    if event.rsvp_full?
      errors.add(:base, "This event has reached its RSVP limit")
    end
  end
end
