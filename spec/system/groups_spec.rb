require "rails_helper"

RSpec.describe "Groups", type: :system do
  let(:user) { User.create!(email: "user@example.com", password: "password") }
  let(:other_user) { User.create!(email: "other@example.com", password: "password") }
  let(:group) { Group.create!(name: "Test Group", description: "A test description") }

  def make_organizer(u, g = group)
    g.group_memberships.create!(user: u, role: "organizer")
  end

  def make_member(u, g = group)
    g.group_memberships.create!(user: u, role: "member")
  end

  describe "browsing and joining groups" do
    before { sign_in user }

    it "shows all groups on the index page" do
      group
      Group.create!(name: "Another Group")
      visit groups_path

      expect(page).to have_content("Test Group")
      expect(page).to have_content("Another Group")
    end

    it "allows a user to join a group from the index" do
      group
      visit groups_path

      click_button "Join"
      expect(page).to have_content("You have joined the group")
      expect(page).to have_current_path(group_path(group))
    end

    it "shows View (not Join) for groups the user already belongs to" do
      make_member(user)
      visit groups_path

      expect(page).to have_link("View")
      expect(page).not_to have_button("Join")
    end
  end

  describe "group show page" do
    before { sign_in user }

    it "displays the member list" do
      make_organizer(user)
      make_member(other_user)
      visit group_path(group)

      expect(page).to have_content(user.email)
      expect(page).to have_content(other_user.email)
      expect(page).to have_content("organizer")
      expect(page).to have_content("member")
    end

    it "shows edit and delete controls only to organizers" do
      make_organizer(user)
      visit group_path(group)

      expect(page).to have_link("Edit")
      expect(page).to have_button("Delete")
    end

    it "hides edit and delete controls from non-organizers" do
      make_member(user)
      visit group_path(group)

      expect(page).not_to have_link("Edit")
      expect(page).not_to have_button("Delete")
    end

    it "shows the Join button to non-members" do
      visit group_path(group)
      expect(page).to have_button("Join Group")
    end

    it "hides the Join button from existing members" do
      make_member(user)
      visit group_path(group)
      expect(page).not_to have_button("Join Group")
    end
  end

  describe "organizer actions" do
    before { sign_in user; make_organizer(user) }

    it "allows organizer to promote a member" do
      make_member(other_user)
      visit group_path(group)

      click_button "Make Organizer"
      expect(page).to have_content("is now an organizer")

      visit group_path(group)
      within("li", text: other_user.email) do
        expect(page).to have_content("organizer")
      end
    end

    it "allows organizer to remove a member" do
      make_member(other_user)
      visit group_path(group)

      within("li", text: other_user.email) do
        click_button "Remove"
      end

      expect(page).to have_content("Member was removed")
      expect(page).not_to have_content(other_user.email)
    end

    it "allows organizer to edit the group" do
      visit edit_group_path(group)
      fill_in "Name", with: "Updated Group Name"
      click_button "Update Group"

      expect(page).to have_content("Group was successfully updated")
      expect(page).to have_content("Updated Group Name")
    end
  end

  describe "member leaving" do
    before { sign_in user; make_member(user) }

    it "allows a member to leave the group" do
      visit group_path(group)

      click_button "Leave"

      expect(page).to have_content("You have left the group")
      expect(page).to have_current_path(groups_path)
    end
  end

  describe "creating a group" do
    before { sign_in user }

    it "creates a group and makes the creator an organizer" do
      visit new_group_path
      fill_in "Name", with: "My New Group"
      fill_in "Description", with: "A great group"
      click_button "Create Group"

      expect(page).to have_content("Group was successfully created")
      expect(page).to have_content("My New Group")

      group = Group.find_by!(name: "My New Group")
      expect(group.organizer?(user)).to be true
    end
  end
end
