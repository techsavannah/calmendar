module EventAuthorization
  extend ActiveSupport::Concern

  private

  def require_event_organizer!
    return if @event.group.organizer?(current_user)
    redirect_to @event, alert: "Only organizers can do that."
  end

  def require_event_visible!
    event = @event
    case event.status
    when "published"
      if event.visibility == "private"
        unless user_signed_in? && event.group.member?(current_user)
          redirect_to root_path, alert: "You must be a group member to view this event."
        end
      end
    when "draft", "canceled"
      unless user_signed_in? && event.group.organizer?(current_user)
        redirect_to root_path, alert: "You are not authorized to view this event."
      end
    end
  end
end
