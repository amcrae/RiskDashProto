# frozen_string_literal: true

# Functions as an adaptor between ID & Role tokens supplied in HTTP Headers
#  and the Devise framework for authentication in Rails.
# The order of events will be:
#   1. The Rack chain receives an HTTP request
#   2. Association of request with existing session is done by default SessionStore middleware.
#   3. The HeaderAuthentication middleware is called
#   3.1 The headers are checked to see if all required ones are present,
#   3.2 If all headers are there, a flag enabling header authentication is stored in session.
#   3.3 All token signatures are verified. May assume they remain valid for a limited period (e.g. 5 seconds).
#   3.4 The application user principal name is extracted from the identity token and stored in session.
#   3.5 If the User does not exist, it is created from the the role+id tokens and saved to DB.
#   3.6 User's granted app roles are derived from the claims token, and are updated in ActiveRecord.
#   4. Warden calls 'valid?'. 
#   4.1 The answer already stored in session hash is returned.
#   5. Warden (may) call 'authenticate!'. 
#   5.1 The UPN is used to load the User instance from ActiveRecord.
#   5.2 The authenticate! method returns the authenticated User instance.
#   6. Warden sets the value of current_user and similar helper objects for use by authorisation.
#   7. Any authorisation framework which reads current_user (e.g. cancancan) or could use the UPN.
#
class HeaderAuthentication

  def initialize(app)
    @app = app
  end

  def call(env)
    @header_configs = Rails.application.config_for(:header_authentication)[:header_configs]
    req = Rack::Request.new(env)
    # reconstructed = reconstruct_headers(env)
    # sesh = req.session
    sesh = env['rack.session']
        
    return @app.call(env)
    
  end

  @@add_to_warden = ->() {
    # Check whether header-based authentication should be used
    # then identify the relevant user
    puts "adding header_authentication..."
    Warden::Strategies.add(:header_authentication) do 
      def valid? 
        puts "header_authentication.valid?"
        # code here to check whether to try and authenticate using this strategy; 
        return session.has_key?('use_header_auth') && session['use_header_auth']
      end 
    
      def authenticate! 
        # code here for doing authentication;
        # if successful, call  
        if session.has_key?('header_auth_upn') then
          upn = session['header_auth_upn']
          user = User.find_by(email: upn)
          return success!(user)
        end
        message = "Could not obtain User from header_auth_upn"
        fail!(message) # where message is the failure message 
      end 
    end 
  }

  def self.add_to_warden()
    @@add_to_warden.call()
  end

end
