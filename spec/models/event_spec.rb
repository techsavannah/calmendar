require "rails_helper"

RSpec.describe Event, type: :model do
  let(:group) { Group.create!(name: "Test Group") }
  let(:base_time) { Time.current.change(sec: 0) }

  def build_event(overrides = {})
    Event.new({
      group: group,
      title: "Test Event",
      starts_at: base_time + 1.day,
      ends_at: base_time + 1.day + 2.hours,
      status: "draft",
      visibility: "public"
    }.merge(overrides))
  end

  def create_event(overrides = {})
    build_event(overrides).tap(&:save!)
  end

  describe "validations" do
    it "is valid with required fields" do
      expect(build_event).to be_valid
    end

    it "requires a title" do
      expect(build_event(title: "")).not_to be_valid
    end

    it "requires starts_at" do
      event = build_event
      event.starts_at = nil
      expect(event).not_to be_valid
    end

    it "requires ends_at" do
      event = build_event
      event.ends_at = nil
      expect(event).not_to be_valid
    end

    it "requires ends_at to be after starts_at" do
      event = build_event(ends_at: base_time + 1.day - 1.hour)
      expect(event).not_to be_valid
      expect(event.errors[:ends_at]).to be_present
    end

    it "rejects ends_at equal to starts_at" do
      t = base_time + 1.day
      event = build_event(starts_at: t, ends_at: t)
      expect(event).not_to be_valid
    end

    it "requires a valid status" do
      expect(build_event(status: "unknown")).not_to be_valid
    end

    it "requires a valid visibility" do
      expect(build_event(visibility: "secret")).not_to be_valid
    end

    it "accepts all valid statuses" do
      Event::STATUSES.each do |s|
        expect(build_event(status: s)).to be_valid
      end
    end

    it "accepts all valid visibilities" do
      Event::VISIBILITIES.each do |v|
        expect(build_event(visibility: v)).to be_valid
      end
    end
  end

  describe "scopes" do
    before do
      create_event(status: "published", starts_at: base_time + 1.day, ends_at: base_time + 1.day + 1.hour)
      create_event(status: "draft",     starts_at: base_time + 2.days, ends_at: base_time + 2.days + 1.hour)
      create_event(status: "canceled",  starts_at: base_time + 3.days, ends_at: base_time + 3.days + 1.hour)
    end

    it ".published returns only published events" do
      expect(Event.published.count).to eq(1)
      expect(Event.published.first.status).to eq("published")
    end

    it ".draft returns only draft events" do
      expect(Event.draft.count).to eq(1)
    end

    it ".canceled returns only canceled events" do
      expect(Event.canceled.count).to eq(1)
    end

    it ".upcoming returns events starting in the future" do
      past_event = create_event(starts_at: base_time - 2.days, ends_at: base_time - 1.day)
      upcoming = Event.upcoming
      expect(upcoming).not_to include(past_event)
    end

    it ".public_visibility returns only public events" do
      create_event(visibility: "private")
      public_events = Event.public_visibility
      expect(public_events.map(&:visibility)).to all(eq("public"))
    end
  end

  describe "#rsvp_open?" do
    let(:event) { create_event(status: "published") }

    it "returns true for a published event with no rsvp time restrictions" do
      expect(event.rsvp_open?).to be true
    end

    it "returns false for a draft event" do
      expect(create_event(status: "draft").rsvp_open?).to be false
    end

    it "returns false for a canceled event" do
      expect(create_event(status: "canceled").rsvp_open?).to be false
    end

    it "returns false when rsvp_opens_at is in the future" do
      event.update!(rsvp_opens_at: 1.hour.from_now)
      expect(event.rsvp_open?).to be false
    end

    it "returns true when rsvp_opens_at is in the past" do
      event.update!(rsvp_opens_at: 1.hour.ago)
      expect(event.rsvp_open?).to be true
    end

    it "returns false when rsvp_closes_at is in the past" do
      event.update!(rsvp_closes_at: 1.hour.ago)
      expect(event.rsvp_open?).to be false
    end

    it "returns true when rsvp_closes_at is in the future" do
      event.update!(rsvp_closes_at: 1.hour.from_now)
      expect(event.rsvp_open?).to be true
    end
  end

  describe "#rsvp_full?" do
    let(:user) { User.create!(email: "u@example.com", password: "password") }
    let(:event) { create_event(status: "published", rsvp_limit: 1) }

    it "returns false when under the limit" do
      expect(event.rsvp_full?).to be false
    end

    it "returns true when at the limit" do
      event.update!(rsvp_opens_at: nil, rsvp_closes_at: nil)
      EventRsvp.create!(event: event, user: user)
      expect(event.rsvp_full?).to be true
    end

    it "returns false when rsvp_limit is nil" do
      event.update!(rsvp_limit: nil)
      expect(event.rsvp_full?).to be false
    end
  end

  describe "#rsvped_by?" do
    let(:user) { User.create!(email: "u@example.com", password: "password") }
    let(:event) { create_event(status: "published") }

    it "returns false when user has not RSVPed" do
      expect(event.rsvped_by?(user)).to be false
    end

    it "returns true when user has RSVPed" do
      EventRsvp.create!(event: event, user: user)
      expect(event.rsvped_by?(user)).to be true
    end

    it "returns false for nil user" do
      expect(event.rsvped_by?(nil)).to be false
    end
  end

  describe "associations" do
    it "destroys event_rsvps when event is destroyed" do
      user = User.create!(email: "u@example.com", password: "password")
      event = create_event(status: "published")
      EventRsvp.create!(event: event, user: user)
      expect { event.destroy }.to change { EventRsvp.count }.by(-1)
    end
  end
end
