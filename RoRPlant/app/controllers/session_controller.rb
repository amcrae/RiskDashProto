class SessionController < Devise::SessionsController
  before_action :require_no_authentication, :only => []

  def new
    # sign-out matches Devise default requirement of user being
    # non-authenticated when trying to sign-in.
    Rails.logger.debug("Session custom create: doing sign_out of #{current_user&.email} to allow conventional sign in.")
    sign_out
    super
  end

  def create
    # Rails.logger.debug("Session custom create: ... #{current_user.to_json}")
    upn = params().fetch('user', nil)&.fetch('email', nil);
    if upn then
      u = User.find_by(email: upn);
      if u&.auth_type != 'LOCAL' then
        flash[:alert] = t(:auth_method_not_permitted)
        redirect_back(fallback_location: root_path)
        return
      end
      if upn != (current_user&.email) then
        Rails.logger.debug("Session custom create: sign-in post user == #{upn}, current_user == #{current_user&.email}")
      end
    end  
    # Rails.logger.debug("Session custom create: invoking super.")
    super
  end

end
