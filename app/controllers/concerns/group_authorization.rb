module GroupAuthorization
  extend ActiveSupport::Concern

  private

  def require_organizer!
    return if @group.organizer?(current_user)

    redirect_to @group, alert: "Only organizers can do that."
  end

  def require_member_or_organizer!
    return if @group.member?(current_user)

    redirect_to groups_path, alert: "You are not a member of this group."
  end
end
