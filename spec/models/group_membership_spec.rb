require "rails_helper"

RSpec.describe GroupMembership, type: :model do
  let(:user) { User.create!(email: "user@example.com", password: "password") }
  let(:group) { Group.create!(name: "Test Group") }

  describe "validations" do
    it "is valid with role 'member'" do
      membership = GroupMembership.new(group: group, user: user, role: "member")
      expect(membership).to be_valid
    end

    it "is valid with role 'organizer'" do
      membership = GroupMembership.new(group: group, user: user, role: "organizer")
      expect(membership).to be_valid
    end

    it "is invalid with an unrecognized role" do
      membership = GroupMembership.new(group: group, user: user, role: "admin")
      expect(membership).not_to be_valid
      expect(membership.errors[:role]).to be_present
    end

    it "enforces uniqueness of user scoped to group" do
      GroupMembership.create!(group: group, user: user, role: "member")
      duplicate = GroupMembership.new(group: group, user: user, role: "organizer")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to be_present
    end

    it "allows the same user in different groups" do
      other_group = Group.create!(name: "Other Group")
      GroupMembership.create!(group: group, user: user, role: "member")
      other_membership = GroupMembership.new(group: other_group, user: user, role: "member")
      expect(other_membership).to be_valid
    end
  end

  describe "associations" do
    it "belongs to a group" do
      expect(described_class.reflect_on_association(:group).macro).to eq(:belongs_to)
    end

    it "belongs to a user" do
      expect(described_class.reflect_on_association(:user).macro).to eq(:belongs_to)
    end
  end
end
