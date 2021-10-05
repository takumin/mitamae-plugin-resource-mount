module ::MItamae
  module Plugin
    module Resource
      class Mount < ::MItamae::Resource::Base
        define_attribute :action, default: :present
        define_attribute :device, type: String
        define_attribute :point, type: String, required: true, default_name: true
        define_attribute :type, type: String
        define_attribute :options, type: Array
        define_attribute :dump, type: Integer
        define_attribute :pass, type: Integer
        define_attribute :force, type: Bool, default: false

        self.available_actions = [:present, :absent]
      end
    end
  end
end
