class EventsController < ApplicationController
  include EventAuthorization

  skip_before_action :authenticate_user!, only: [ :show ]
  before_action :set_group, only: [ :index, :new, :create ]
  before_action :set_event, only: [ :show, :edit, :update, :destroy ]
  before_action :require_event_visible!, only: [ :show ]
  before_action :require_group_member_or_organizer!, only: [ :index ]
  before_action :require_group_organizer!, only: [ :new, :create ]
  before_action :require_event_organizer!, only: [ :edit, :update, :destroy ]

  def index
    @events = if @group.organizer?(current_user)
      @group.events.order(starts_at: :asc)
    else
      @group.events.published.order(starts_at: :asc)
    end
  end

  def show
    @rsvp_count = @event.event_rsvps.count
    @user_rsvp = current_user ? @event.event_rsvps.find_by(user: current_user) : nil
  end

  def new
    @event = @group.events.build
  end

  def create
    @event = @group.events.build(event_params)
    if @event.save
      redirect_to @event, notice: "Event was created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @event.update(event_params)
      redirect_to @event, notice: "Event was updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    group = @event.group
    @event.destroy
    redirect_to group_events_path(group), notice: "Event was deleted."
  end

  private

  def set_group
    @group = Group.find(params[:group_id])
  end

  def set_event
    @event = Event.find(params[:id])
  end

  def require_group_member_or_organizer!
    unless @group.member?(current_user)
      redirect_to @group, alert: "You must be a member to view this group's events."
    end
  end

  def require_group_organizer!
    unless @group.organizer?(current_user)
      redirect_to @group, alert: "Only organizers can do that."
    end
  end

  def event_params
    params.expect(event: [ :title, :description, :starts_at, :ends_at, :location,
                            :status, :visibility, :rsvp_limit, :rsvp_opens_at, :rsvp_closes_at ])
  end
end
