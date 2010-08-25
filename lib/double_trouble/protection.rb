module DoubleTrouble
  module Protection
    extend ActiveSupport::Concern

    included do
      class_inheritable_accessor :allow_double_trouble_protection
      class_inheritable_accessor :double_trouble_resource_name
      cattr_accessor             :double_trouble_nonce_store
      cattr_accessor             :double_trouble_nonce_param
      helper_method              :protect_against_double_trouble?, :double_trouble_nonce_param, :double_trouble_form_nonce

      self.allow_double_trouble_protection = true
    end

    module ClassMethods
      def protect_from_double_trouble(resource_name, options = {})
        self.double_trouble_resource_name   = resource_name
        self.double_trouble_nonce_param   ||= :form_nonce
        self.double_trouble_nonce_store   ||= CachedNonce

        around_filter :double_trouble_protection, options.slice(:only, :except)
      end
    end

    module InstanceMethods
      protected

      def double_trouble_protection
        if protect_against_double_trouble?
          nonce = params[double_trouble_nonce_param]
          store = double_trouble_nonce_store

          store.valid?(nonce) || raise(InvalidNonce)
          yield
          instance_variable_get("@#{double_trouble_resource_name}").tap do |resource|
            resource.present? && !resource.new_record? && store.store!(nonce)
          end
        else
          yield
        end
      end

      def double_trouble_form_nonce
        ActiveSupport::SecureRandom.base64(32)
      end

      def protect_against_double_trouble?
        allow_double_trouble_protection && double_trouble_resource_name && double_trouble_nonce_store && double_trouble_nonce_param
      end
    end
  end
end
