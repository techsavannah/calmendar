require "rails_helper"

RSpec.describe EventRsvp, type: :model do
  let(:group) { Group.create!(name: "Test Group") }
  let(:user)  { User.create!(email: "user@example.com", password: "password") }
  let(:other_user) { User.create!(email: "other@example.com", password: "password") }
  let(:base_time) { Time.current.change(sec: 0) }

  def published_event(overrides = {})
    Event.create!({
      group: group,
      title: "Open Event",
      starts_at: base_time + 1.day,
      ends_at: base_time + 1.day + 2.hours,
      status: "published",
      visibility: "public"
    }.merge(overrides))
  end

  describe "associations" do
    it "belongs to event" do
      expect(described_class.reflect_on_association(:event).macro).to eq(:belongs_to)
    end

    it "belongs to user" do
      expect(described_class.reflect_on_association(:user).macro).to eq(:belongs_to)
    end
  end

  describe "uniqueness validation" do
    it "prevents the same user from RSVPing twice to the same event" do
      event = published_event
      EventRsvp.create!(event: event, user: user)
      duplicate = EventRsvp.new(event: event, user: user)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to be_present
    end

    it "allows the same user to RSVP to different events" do
      event1 = published_event(title: "Event 1")
      event2 = published_event(title: "Event 2")
      EventRsvp.create!(event: event1, user: user)
      expect(EventRsvp.new(event: event2, user: user)).to be_valid
    end

    it "allows different users to RSVP to the same event" do
      event = published_event
      EventRsvp.create!(event: event, user: user)
      expect(EventRsvp.new(event: event, user: other_user)).to be_valid
    end
  end

  describe "#event_must_accept_rsvps" do
    it "blocks RSVP when event is a draft" do
      event = Event.create!(group: group, title: "Draft", starts_at: base_time + 1.day,
                            ends_at: base_time + 1.day + 1.hour, status: "draft")
      rsvp = EventRsvp.new(event: event, user: user)
      expect(rsvp).not_to be_valid
      expect(rsvp.errors[:base]).to be_present
    end

    it "blocks RSVP when event is canceled" do
      event = Event.create!(group: group, title: "Canceled", starts_at: base_time + 1.day,
                            ends_at: base_time + 1.day + 1.hour, status: "canceled")
      rsvp = EventRsvp.new(event: event, user: user)
      expect(rsvp).not_to be_valid
    end

    it "blocks RSVP when rsvp_opens_at is in the future" do
      event = published_event(rsvp_opens_at: 1.hour.from_now)
      rsvp = EventRsvp.new(event: event, user: user)
      expect(rsvp).not_to be_valid
    end

    it "blocks RSVP when rsvp_closes_at is in the past" do
      event = published_event(rsvp_closes_at: 1.hour.ago)
      rsvp = EventRsvp.new(event: event, user: user)
      expect(rsvp).not_to be_valid
    end

    it "blocks RSVP when event is full" do
      event = published_event(rsvp_limit: 1)
      EventRsvp.create!(event: event, user: other_user)
      rsvp = EventRsvp.new(event: event, user: user)
      expect(rsvp).not_to be_valid
      expect(rsvp.errors[:base].join).to include("limit")
    end

    it "does not run on update" do
      event = published_event
      rsvp = EventRsvp.create!(event: event, user: user)
      event.update!(status: "canceled")
      expect(rsvp.save).to be true
    end
  end
end
