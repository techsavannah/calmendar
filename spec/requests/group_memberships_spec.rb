require "rails_helper"

RSpec.describe "GroupMemberships", type: :request do
  let(:user) { User.create!(email: "user@example.com", password: "password") }
  let(:other_user) { User.create!(email: "other@example.com", password: "password") }
  let(:group) { Group.create!(name: "Test Group") }

  def make_organizer(u, g = group)
    g.group_memberships.create!(user: u, role: "organizer")
  end

  def make_member(u, g = group)
    g.group_memberships.create!(user: u, role: "member")
  end

  describe "POST /groups/:group_id/group_memberships" do
    context "when unauthenticated" do
      it "redirects to sign in" do
        post group_group_memberships_path(group)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated" do
      before { sign_in user }

      it "joins the group as a member" do
        expect {
          post group_group_memberships_path(group)
        }.to change(GroupMembership, :count).by(1)

        expect(group.member?(user)).to be true
        expect(group.organizer?(user)).to be false
        expect(response).to redirect_to(group_path(group))
      end

      it "prevents joining twice" do
        make_member(user)
        expect {
          post group_group_memberships_path(group)
        }.not_to change(GroupMembership, :count)

        expect(response).to redirect_to(group_path(group))
      end
    end
  end

  describe "DELETE /group_memberships/:id" do
    context "when unauthenticated" do
      it "redirects to sign in" do
        membership = make_member(user)
        delete group_membership_path(membership)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when leaving as the member themselves" do
      before { sign_in user }

      it "removes the membership" do
        membership = make_member(user)
        expect {
          delete group_membership_path(membership)
        }.to change(GroupMembership, :count).by(-1)

        expect(response).to redirect_to(groups_path)
      end

      it "prevents removing the last organizer" do
        membership = make_organizer(user)
        delete group_membership_path(membership)
        expect(GroupMembership.exists?(membership.id)).to be true
        expect(response).to redirect_to(group_path(group))
      end
    end

    context "when an organizer removes another member" do
      before { sign_in user; make_organizer(user) }

      it "removes the target member" do
        target = make_member(other_user)
        expect {
          delete group_membership_path(target)
        }.to change(GroupMembership, :count).by(-1)

        expect(response).to redirect_to(group_path(group))
      end
    end

    context "when a non-organizer tries to remove someone else" do
      before { sign_in user; make_member(user) }

      it "denies the action" do
        target = make_member(other_user)
        delete group_membership_path(target)
        expect(GroupMembership.exists?(target.id)).to be true
        expect(response).to redirect_to(group_path(group))
      end
    end
  end

  describe "PATCH /group_memberships/:id" do
    context "when unauthenticated" do
      it "redirects to sign in" do
        membership = make_member(user)
        patch group_membership_path(membership), params: { group_membership: { role: "organizer" } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated as an organizer" do
      before { sign_in other_user; make_organizer(other_user) }

      it "promotes a member to organizer" do
        membership = make_member(user)
        patch group_membership_path(membership), params: { group_membership: { role: "organizer" } }
        expect(membership.reload.role).to eq("organizer")
        expect(response).to redirect_to(group_path(group))
      end
    end

    context "when authenticated as a non-organizer" do
      before { sign_in user; make_member(user) }

      it "denies the promotion" do
        target = make_member(other_user)
        patch group_membership_path(target), params: { group_membership: { role: "organizer" } }
        expect(target.reload.role).to eq("member")
        expect(response).to redirect_to(group_path(group))
      end
    end
  end
end
