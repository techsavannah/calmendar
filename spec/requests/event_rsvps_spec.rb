require "rails_helper"

RSpec.describe "EventRsvps", type: :request do
  let(:user)       { User.create!(email: "user@example.com", password: "password") }
  let(:other_user) { User.create!(email: "other@example.com", password: "password") }
  let(:group)      { Group.create!(name: "Test Group") }
  let(:base_time)  { Time.current.change(sec: 0) }

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

  describe "POST /events/:event_id/event_rsvps" do
    let(:event) { published_event }

    it "redirects unauthenticated users to sign in" do
      post event_event_rsvps_path(event)
      expect(response).to redirect_to(new_user_session_path)
    end

    it "creates an RSVP and redirects to the event" do
      sign_in user
      expect {
        post event_event_rsvps_path(event)
      }.to change(EventRsvp, :count).by(1)
      expect(response).to redirect_to(event_path(event))
      expect(flash[:notice]).to be_present
    end

    it "redirects with alert when RSVPs are not open (draft)" do
      draft = Event.create!(group: group, title: "Draft", starts_at: base_time + 1.day,
                            ends_at: base_time + 1.day + 1.hour, status: "draft")
      sign_in user
      post event_event_rsvps_path(draft)
      expect(response).to redirect_to(event_path(draft))
      expect(flash[:alert]).to be_present
    end

    it "redirects with alert when RSVPs haven't opened yet" do
      event = published_event(rsvp_opens_at: 1.hour.from_now)
      sign_in user
      post event_event_rsvps_path(event)
      expect(response).to redirect_to(event_path(event))
      expect(flash[:alert]).to be_present
    end

    it "redirects with alert when RSVPs are closed" do
      event = published_event(rsvp_closes_at: 1.hour.ago)
      sign_in user
      post event_event_rsvps_path(event)
      expect(response).to redirect_to(event_path(event))
      expect(flash[:alert]).to be_present
    end

    it "redirects with alert when event is full" do
      event = published_event(rsvp_limit: 1)
      EventRsvp.create!(event: event, user: other_user)
      sign_in user
      post event_event_rsvps_path(event)
      expect(response).to redirect_to(event_path(event))
      expect(flash[:alert]).to be_present
    end

    it "redirects with alert when user has already RSVPed" do
      EventRsvp.create!(event: event, user: user)
      sign_in user
      post event_event_rsvps_path(event)
      expect(response).to redirect_to(event_path(event))
      expect(flash[:alert]).to be_present
    end
  end

  describe "DELETE /event_rsvps/:id" do
    let(:event) { published_event }
    let!(:rsvp) { EventRsvp.create!(event: event, user: user) }

    it "redirects unauthenticated users to sign in" do
      delete event_rsvp_path(rsvp)
      expect(response).to redirect_to(new_user_session_path)
    end

    it "allows user to cancel their own RSVP" do
      sign_in user
      expect {
        delete event_rsvp_path(rsvp)
      }.to change(EventRsvp, :count).by(-1)
      expect(response).to redirect_to(event_path(event))
      expect(flash[:notice]).to be_present
    end

    it "prevents user from canceling another's RSVP" do
      sign_in other_user
      delete event_rsvp_path(rsvp)
      expect(EventRsvp.exists?(rsvp.id)).to be true
      expect(response).to redirect_to(event_path(event))
      expect(flash[:alert]).to be_present
    end
  end
end
