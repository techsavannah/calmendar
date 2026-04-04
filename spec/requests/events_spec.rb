require "rails_helper"

RSpec.describe "Events", type: :request do
  let(:organizer) { User.create!(email: "organizer@example.com", password: "password") }
  let(:member)    { User.create!(email: "member@example.com", password: "password") }
  let(:outsider)  { User.create!(email: "outsider@example.com", password: "password") }
  let(:group) { Group.create!(name: "Test Group") }
  let(:base_time) { Time.current.change(sec: 0) }

  def make_organizer(u, g = group)
    g.group_memberships.create!(user: u, role: "organizer")
  end

  def make_member(u, g = group)
    g.group_memberships.create!(user: u, role: "member")
  end

  def create_event(overrides = {})
    Event.create!({
      group: group,
      title: "Test Event",
      starts_at: base_time + 1.day,
      ends_at: base_time + 1.day + 2.hours,
      status: "published",
      visibility: "public"
    }.merge(overrides))
  end

  let(:event_params) do
    {
      title: "New Event",
      starts_at: (base_time + 2.days).strftime("%Y-%m-%dT%H:%M"),
      ends_at: (base_time + 2.days + 2.hours).strftime("%Y-%m-%dT%H:%M"),
      status: "draft",
      visibility: "public"
    }
  end

  describe "GET /groups/:group_id/events" do
    before { make_organizer(organizer); make_member(member) }

    it "redirects unauthenticated users" do
      get group_events_path(group)
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects non-member outsiders" do
      sign_in outsider
      get group_events_path(group)
      expect(response).to redirect_to(group_path(group))
    end

    it "returns 200 for group members" do
      sign_in member
      get group_events_path(group)
      expect(response).to have_http_status(:ok)
    end

    it "returns 200 for organizer" do
      sign_in organizer
      get group_events_path(group)
      expect(response).to have_http_status(:ok)
    end

    it "shows all statuses to organizer" do
      create_event(status: "draft", title: "Draft")
      create_event(status: "published", title: "Published")
      sign_in organizer
      get group_events_path(group)
      expect(response.body).to include("Draft", "Published")
    end

    it "shows only published events to members" do
      create_event(status: "draft", title: "Hidden Draft")
      create_event(status: "published", title: "Visible Published")
      sign_in member
      get group_events_path(group)
      expect(response.body).to include("Visible Published")
      expect(response.body).not_to include("Hidden Draft")
    end
  end

  describe "GET /events/:id (public + published)" do
    let(:event) { create_event(status: "published", visibility: "public") }

    it "returns 200 for unauthenticated visitors" do
      get event_path(event)
      expect(response).to have_http_status(:ok)
    end

    it "returns 200 for a member" do
      make_member(member)
      sign_in member
      get event_path(event)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /events/:id (private + published)" do
    let(:event) { create_event(status: "published", visibility: "private") }

    it "redirects unauthenticated visitors" do
      get event_path(event)
      expect(response).to redirect_to(root_path)
    end

    it "redirects outsiders (not a group member)" do
      sign_in outsider
      get event_path(event)
      expect(response).to redirect_to(root_path)
    end

    it "returns 200 for group members" do
      make_member(member)
      sign_in member
      get event_path(event)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /events/:id (draft)" do
    let(:event) { create_event(status: "draft") }

    it "redirects unauthenticated visitors" do
      get event_path(event)
      expect(response).to redirect_to(root_path)
    end

    it "redirects non-organizer members" do
      make_member(member)
      sign_in member
      get event_path(event)
      expect(response).to redirect_to(root_path)
    end

    it "returns 200 for organizers" do
      make_organizer(organizer)
      sign_in organizer
      get event_path(event)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /groups/:group_id/events/new" do
    it "redirects unauthenticated users" do
      get new_group_event_path(group)
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects non-organizers" do
      make_member(member)
      sign_in member
      get new_group_event_path(group)
      expect(response).to redirect_to(group_path(group))
    end

    it "returns 200 for organizers" do
      make_organizer(organizer)
      sign_in organizer
      get new_group_event_path(group)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /groups/:group_id/events" do
    before { make_organizer(organizer) }

    it "redirects unauthenticated users" do
      post group_events_path(group), params: { event: event_params }
      expect(response).to redirect_to(new_user_session_path)
    end

    it "creates an event and redirects" do
      sign_in organizer
      expect {
        post group_events_path(group), params: { event: event_params }
      }.to change(Event, :count).by(1)
      expect(response).to redirect_to(event_path(Event.last))
    end

    it "re-renders new with errors on invalid params" do
      sign_in organizer
      post group_events_path(group), params: { event: event_params.merge(title: "") }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /events/:id/edit" do
    let(:event) { create_event(status: "draft") }

    it "redirects unauthenticated users" do
      get edit_event_path(event)
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects non-organizers" do
      make_member(member)
      sign_in member
      get edit_event_path(event)
      expect(response).to redirect_to(event_path(event))
    end

    it "returns 200 for organizers" do
      make_organizer(organizer)
      sign_in organizer
      get edit_event_path(event)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /events/:id" do
    let(:event) { create_event(status: "draft") }

    it "redirects non-organizers" do
      make_member(member)
      sign_in member
      patch event_path(event), params: { event: { title: "Changed" } }
      expect(response).to redirect_to(event_path(event))
    end

    it "updates the event for organizers" do
      make_organizer(organizer)
      sign_in organizer
      patch event_path(event), params: { event: { title: "Updated Title", status: "published" } }
      expect(event.reload.title).to eq("Updated Title")
      expect(event.reload.status).to eq("published")
    end

    it "re-renders edit with errors on invalid params" do
      make_organizer(organizer)
      sign_in organizer
      patch event_path(event), params: { event: { title: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /events/:id" do
    let(:event) { create_event(status: "draft") }

    it "redirects non-organizers" do
      make_member(member)
      sign_in member
      delete event_path(event)
      expect(response).to redirect_to(event_path(event))
    end

    it "destroys the event for organizers" do
      make_organizer(organizer)
      sign_in organizer
      delete event_path(event)
      expect(Event.exists?(event.id)).to be false
      expect(response).to redirect_to(group_events_path(group))
    end
  end
end
