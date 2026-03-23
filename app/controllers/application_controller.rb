class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Require authentication for all controllers by default.
  # To allow unauthenticated access to specific actions, add to that controller:
  #   skip_before_action :authenticate_user!, only: [:index, :show]
  before_action :authenticate_user!

  def after_sign_in_path_for(_resource_or_scope)
    home_path
  end

  def after_sign_out_path_for(_resource_or_scope)
    new_user_session_path
  end
end
