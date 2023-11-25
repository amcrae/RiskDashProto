# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # # Middleware is currently used instead to do updates.
  # before_action :refresh_user!

  before_action :log_user_action!

  # This point is an alternative place (aside from middleware)
  #  to update the details of the User from the external source.
  def refresh_user!
    ts = Time.now()
    if session.has_key?(HeaderAuthentication::SESS_KEY_HA_AUTH_USER) \
      && current_user()
    then
      account = session[HeaderAuthentication::SESS_KEY_HA_AUTH_USER];
      current_user().full_name = account.full_name
      current_user().role_name = account.role_name
      Rails.logger.info("#{ts} User attributes for #{account.email} updated from Devise current_user.");
    end
  end

  def log_user_action!
    ts = Time.now()
    if current_user()
      uname = "User " + current_user()[:email]
    else
      uname = "*UNKNOWN* user"
    end
    Rails.logger.info("#{ts} *** #{uname} executing #{self.class} with #{params()}");
  end

end
