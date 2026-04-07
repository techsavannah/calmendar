class User < ApplicationRecord
  has_many :group_memberships, dependent: :destroy
  has_many :groups, through: :group_memberships
  has_many :event_rsvps, dependent: :destroy

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # ==> OmniAuth readiness
  # When adding Google/GitHub/Apple login, replace the line above with:
  #
  #   devise :database_authenticatable, :registerable,
  #          :recoverable, :rememberable, :validatable,
  #          :omniauthable, omniauth_providers: %i[google_oauth2 github apple]
  #
  # Also add uid and provider string columns to the users table:
  #   bin/rails generate migration AddOmniauthToUsers uid:string provider:string
  #
  # See config/initializers/devise.rb for the full setup checklist.
end
