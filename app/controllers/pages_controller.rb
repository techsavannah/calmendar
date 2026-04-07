class PagesController < ApplicationController
  def home
    group_ids = current_user.group_memberships.pluck(:group_id)
    @upcoming_events = Event.published
                            .where(group_id: group_ids)
                            .upcoming
                            .order(:starts_at)
                            .limit(6)
    @discover_events = Event.published
                            .public_visibility
                            .where.not(group_id: group_ids)
                            .upcoming
                            .order(:starts_at)
                            .limit(6)
  end
end
