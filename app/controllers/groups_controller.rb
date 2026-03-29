class GroupsController < ApplicationController
  include GroupAuthorization

  before_action :set_group, only: [ :show, :edit, :update, :destroy ]
  before_action :require_organizer!, only: [ :edit, :update, :destroy ]

  def index
    @groups = Group.includes(:organizers).order(:name)
  end

  def show
    @memberships = @group.group_memberships.includes(:user).order(:role, "users.email")
  end

  def new
    @group = Group.new
  end

  def create
    @group = Group.new(group_params)

    if @group.save
      @group.group_memberships.create!(user: current_user, role: "organizer")
      redirect_to @group, notice: "Group was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @group.update(group_params)
      redirect_to @group, notice: "Group was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @group.destroy
    redirect_to groups_path, notice: "Group was successfully deleted."
  end

  private

  def set_group
    @group = Group.find(params[:id])
  end

  def group_params
    params.expect(group: [ :name, :description ])
  end
end
