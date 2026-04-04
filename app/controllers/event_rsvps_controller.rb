class EventRsvpsController < ApplicationController
  before_action :set_event, only: [ :create ]
  before_action :set_rsvp, only: [ :destroy ]

  def create
    @rsvp = @event.event_rsvps.build(user: current_user)
    if @rsvp.save
      redirect_to @event, notice: "You're going!"
    else
      redirect_to @event, alert: @rsvp.errors.full_messages.to_sentence
    end
  end

  def destroy
    unless @rsvp.user == current_user
      redirect_to @rsvp.event, alert: "You can only cancel your own RSVP."
      return
    end
    @rsvp.destroy
    redirect_to @rsvp.event, notice: "Your RSVP has been canceled."
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end

  def set_rsvp
    @rsvp = EventRsvp.find(params[:id])
  end
end
