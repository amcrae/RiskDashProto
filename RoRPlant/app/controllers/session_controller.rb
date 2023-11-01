class SessionController < Devise::SessionsController

  def create
    Rails.logger.debug("Session custom create")
    upn = params().fetch('user', nil)&.fetch('email', nil);
    if upn then
      u = User.find_by(email: upn);
      if u.auth_type != 'LOCAL' then
        sign_out
        flash[:alert] = t(:auth_method_not_permitted)
        redirect_back(fallback_location: root_path)
        return
      end
    end  
    super
  end

end
