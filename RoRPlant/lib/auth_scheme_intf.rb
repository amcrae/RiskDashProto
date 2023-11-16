# frozen_string_literal: true

module HeaderAuthentication
  
  # AuthSchemeIntf defines an interface (in behavioural documentation and in
  # expected method signatures) for how different HTTP header-based authentication 
  # schemes can be implemented, while inheriting most generic functionality
  # for working with HTTP headers from the Rack pipeline and integration with Devise.
  # 
  # As most custom behviour is expected to use no more information than is given
  # in these methods' parameters, these methods must be implemented as class methods
  # by extend-ing the custom scheme's module with this module and overriding the method bodies.
  # HeaderAuthentication requires methods of these names to be implemented
  # on a concrete class at runtime.
  module AuthSchemeIntf
    # Return the list of HTTP headers required by this auth scheme.
    def required_header_names()
      raise NotImplementedError, "#{self} must implement the method #{__method__}"      
    end

    # Return an object used as the key for verifying the signature embedde in a header value.
    #  header_value == the content of the HTTP header (includes the signature wrapper).
    #  config == the current configuration hash.
    # Must return nil if signatures are not required (and not expected) on the given header.
    # Expected to raise an exception if the key cannot be retrieved.
    def get_signature_verification_key(header_name, header_value, config)
      raise NotImplementedError, "#{self} must implement the method #{__method__}";
    end

    # Return true when the signed value passes signature verification, false if it does not.
    # Raising an exception will also result in signature being untrusted.
    #  header_value == The complete header value.
    #  signing_key == the object obtained from get_signature_verification_key
    #  config == the current configuration hash.
    def verify_signed_value(header_name, header_value, signing_key, config)
      raise NotImplementedError, "#{self} must implement the method #{__method__}";
    end

    # Update the given user_info data structure with attributes of the
    # authenticated user given by the external Identity Provider.
    # Updates can be made to user attributes or roles list depending on the header given.
    # Return any additions made as a hash, such that if no changes are made a 0 sized hash is returned.
    # config == the current header auth configuration
    def get_user_details(header_name, config, header_value, req, sesh, user_info)
      raise NotImplementedError, "#{self} must implement the method #{__method__}";
    end

    # Test whether a header value is valid with respect to all data gathered from all headers.
    # If no test is to be done on a header, return nil.
    # Otherwise return true or false depending on header value validity.
    def user_details_validator(header_name, header_value, user_info)
      raise NotImplementedError, "#{self} must implement the method #{__method__}";
    end
  end
end
