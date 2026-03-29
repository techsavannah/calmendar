class GroupMembershipsController < ApplicationController
  include GroupAuthorization

  before_action :set_membership, only: [ :update, :destroy ]
  before_action :set_group
  before_action :require_organizer!, only: [ :update ]

  def create
    if @group.member?(current_user)
      redirect_to @group, alert: "You are already a member of this group."
      return
    end

    @group.group_memberships.create!(user: current_user, role: "member")
    redirect_to @group, notice: "You have joined the group."
  end

  def update
    if @membership.update(role: "organizer")
      redirect_to @group, notice: "#{@membership.user.email} is now an organizer."
    else
      redirect_to @group, alert: "Could not promote member."
    end
  end

  def destroy
    unless current_user == @membership.user || @group.organizer?(current_user)
      redirect_to @group, alert: "You cannot remove that member."
      return
    end

    if @membership.role == "organizer" && @group.organizers.count == 1
      redirect_to @group, alert: "Cannot remove the last organizer."
      return
    end

    @membership.destroy
    if current_user == @membership.user
      redirect_to groups_path, notice: "You have left the group."
    else
      redirect_to @group, notice: "Member was removed."
    end
  end

  private

  def set_membership
    @membership = GroupMembership.find(params[:id])
  end

  def set_group
    @group = if params[:group_id]
      Group.find(params[:group_id])
    else
      @membership.group
    end
  end
end
