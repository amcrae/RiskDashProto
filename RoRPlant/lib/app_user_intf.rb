# frozen_string_literal: true

module HeaderAuthentication
  
  # Contract expected by HeaderAuthentication to perform
  # two-way mapping between generic logic and the application-
  # -specific ActiveRecord model of a User and their granted Roles.
  # Expected to be implemented in an app-specific module, then used
  # as class methods by `extend`ing an application class with that module.
  module AppUserIntf
    
    # key format of object passed to create_app_user_from_template
    @@_blank_user_info = {
      upn: nil,
      app_account: nil,
      user_attributes: {},
      ext_roles_array: []
    }

    # Given a user principal name string, return the ActiveRecord object which models that application User.
    def load_app_user_by_upn(upn)
      # Concrete class must override and implement.
      raise NotImplementedError, "#{self.class} must implement the method #{__method__}"
    end

    # Given an ActiveRecord application model of the User, extract the field used as UPN.
    def get_upn_from_app_user(account)
      # Concrete class must override and implement.
      raise NotImplementedError, "#{self.class} must implement the method #{__method__}"
    end

    # Given an ActiveRecord application model of the User, 
    #  determine if they require HTTP header token based authentication.
    def app_user_needs_headerauth?(account)
      # Concrete class must override and implement.
      raise NotImplementedError, "#{self.class} must implement the method #{__method__}"
    end

    # Given a template is returned by the AuthSchemeIntf#get_user_template (e.g. a Hash)
    #  create an ActiveRecord model of the User with the attributes populated from the template.
    # The user_info Hash will have keys shown in AppUserIntf#_blank_user_info .
    def create_app_user_from_template(user_info)
      # Concrete class must override and implement.
      raise NotImplementedError, "#{self.class} must implement the method #{__method__}"
    end

    # Given a template updated by the AuthSchemeIntf#get_user_details (e.g. a Hash)
    #  update an extant ActiveRecord of the User with the attributes populated from the template.
    # The user_info Hash will have keys shown in AppUserIntf#_blank_user_info .
    def update_app_user(user_info)
      raise NotImplementedError, "#{self.class} must implement the method #{__method__}"
    end

    # Given 1) a list of all externally-provided role names granted to a user, 
    #  and 2) a target ActiveRecord User model 'account' object,
    #  translate the external role names to application-specific roles and 
    #  update the User model with this new complete list of granted app roles.
    def set_app_user_roles(roles_array, account)
      # Concrete class must override and implement.
      raise NotImplementedError, "#{self.class} must implement the method #{__method__}"
    end
  end
  
end
