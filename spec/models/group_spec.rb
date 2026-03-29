require "rails_helper"

RSpec.describe Group, type: :model do
  let(:user) { User.create!(email: "user@example.com", password: "password") }
  let(:other_user) { User.create!(email: "other@example.com", password: "password") }
  let(:group) { Group.create!(name: "Test Group", description: "A test group") }

  describe "validations" do
    it "is valid with a name" do
      expect(group).to be_valid
    end

    it "requires a name" do
      group = Group.new(name: "")
      expect(group).not_to be_valid
      expect(group.errors[:name]).to be_present
    end

    it "enforces case-insensitive name uniqueness" do
      Group.create!(name: "Unique Group")
      duplicate = Group.new(name: "unique group")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to be_present
    end

    it "caps description at 1000 characters" do
      group = Group.new(name: "Long Desc", description: "x" * 1001)
      expect(group).not_to be_valid
      expect(group.errors[:description]).to be_present
    end

    it "allows description up to 1000 characters" do
      group = Group.new(name: "Max Desc", description: "x" * 1000)
      expect(group).to be_valid
    end
  end

  describe "associations" do
    it "has many group_memberships" do
      expect(described_class.reflect_on_association(:group_memberships).macro).to eq(:has_many)
    end

    it "destroys memberships when group is destroyed" do
      GroupMembership.create!(group: group, user: user, role: "organizer")
      expect { group.destroy }.to change { GroupMembership.count }.by(-1)
    end
  end

  describe "#organizer?" do
    it "returns true for a user with organizer role" do
      GroupMembership.create!(group: group, user: user, role: "organizer")
      expect(group.organizer?(user)).to be true
    end

    it "returns false for a user with member role" do
      GroupMembership.create!(group: group, user: user, role: "member")
      expect(group.organizer?(user)).to be false
    end

    it "returns false for a user with no membership" do
      expect(group.organizer?(user)).to be false
    end
  end

  describe "#member?" do
    it "returns true for a user with member role" do
      GroupMembership.create!(group: group, user: user, role: "member")
      expect(group.member?(user)).to be true
    end

    it "returns true for a user with organizer role" do
      GroupMembership.create!(group: group, user: user, role: "organizer")
      expect(group.member?(user)).to be true
    end

    it "returns false for a user with no membership" do
      expect(group.member?(user)).to be false
    end
  end

  describe "scoped associations" do
    before do
      GroupMembership.create!(group: group, user: user, role: "organizer")
      GroupMembership.create!(group: group, user: other_user, role: "member")
    end

    it "returns only organizers via #organizers" do
      expect(group.organizers).to contain_exactly(user)
    end

    it "returns only members via #members" do
      expect(group.members).to contain_exactly(other_user)
    end

    it "returns all users via #users" do
      expect(group.users).to contain_exactly(user, other_user)
    end
  end
end
