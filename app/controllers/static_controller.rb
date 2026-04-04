class StaticController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    @upcoming_events = Event.published.public_visibility.upcoming.order(:starts_at).limit(6)
  end
end
