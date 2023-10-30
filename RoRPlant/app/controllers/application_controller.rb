# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :log_user_action!

  def log_user_action!
    ts = Time.now()
    if current_user()
      uname = "User " + current_user()[:email]
    else
      uname = "*UNKNOWN* user"
    end
    Rails.logger.debug("#{ts} *** #{uname} executing #{self.class} with #{params()}");
  end

end
