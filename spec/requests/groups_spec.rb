require "rails_helper"

RSpec.describe "Groups", type: :request do
  let(:user) { User.create!(email: "user@example.com", password: "password") }
  let(:other_user) { User.create!(email: "other@example.com", password: "password") }
  let(:group) { Group.create!(name: "Test Group", description: "A description") }

  def make_organizer(u, g)
    g.group_memberships.create!(user: u, role: "organizer")
  end

  def make_member(u, g)
    g.group_memberships.create!(user: u, role: "member")
  end

  describe "GET /groups" do
    context "when unauthenticated" do
      it "redirects to sign in" do
        get groups_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated" do
      before { sign_in user }

      it "returns 200" do
        get groups_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /groups/:id" do
    context "when unauthenticated" do
      it "redirects to sign in" do
        get group_path(group)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated" do
      before { sign_in user }

      it "returns 200" do
        get group_path(group)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /groups/new" do
    it "redirects unauthenticated users" do
      get new_group_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "returns 200 when authenticated" do
      sign_in user
      get new_group_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /groups" do
    context "when unauthenticated" do
      it "redirects to sign in" do
        post groups_path, params: { group: { name: "New Group" } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated" do
      before { sign_in user }

      it "creates a group and makes the creator an organizer" do
        expect {
          post groups_path, params: { group: { name: "New Group", description: "Desc" } }
        }.to change(Group, :count).by(1)
          .and change(GroupMembership, :count).by(1)

        group = Group.last
        expect(group.organizer?(user)).to be true
        expect(response).to redirect_to(group)
      end

      it "re-renders new with errors on invalid params" do
        post groups_path, params: { group: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /groups/:id/edit" do
    context "when unauthenticated" do
      it "redirects to sign in" do
        get edit_group_path(group)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated as non-organizer" do
      before { sign_in user }

      it "redirects with alert" do
        get edit_group_path(group)
        expect(response).to redirect_to(group_path(group))
      end
    end

    context "when authenticated as organizer" do
      before { sign_in user; make_organizer(user, group) }

      it "returns 200" do
        get edit_group_path(group)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "PATCH /groups/:id" do
    context "when authenticated as non-organizer" do
      before { sign_in user }

      it "redirects with alert" do
        patch group_path(group), params: { group: { name: "Changed" } }
        expect(response).to redirect_to(group_path(group))
      end
    end

    context "when authenticated as organizer" do
      before { sign_in user; make_organizer(user, group) }

      it "updates the group" do
        patch group_path(group), params: { group: { name: "Updated Name" } }
        expect(group.reload.name).to eq("Updated Name")
        expect(response).to redirect_to(group_path(group))
      end

      it "re-renders edit with errors on invalid params" do
        patch group_path(group), params: { group: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /groups/:id" do
    context "when authenticated as non-organizer" do
      before { sign_in user }

      it "redirects with alert" do
        delete group_path(group)
        expect(response).to redirect_to(group_path(group))
      end
    end

    context "when authenticated as organizer" do
      before { sign_in user; make_organizer(user, group) }

      it "destroys the group" do
        delete group_path(group)
        expect(Group.exists?(group.id)).to be false
        expect(response).to redirect_to(groups_path)
      end
    end
  end
end
