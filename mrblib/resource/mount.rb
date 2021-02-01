module ::MItamae
  module Plugin
    module Resource
      class Mount < ::MItamae::Resource::Base
        define_attribute :action, default: :present
        define_attribute :device, type: String, required: true, default: ''
        define_attribute :point, type: String, required: true, default_name: true, default: ''
        define_attribute :type, type: String, default: ''
        define_attribute :options, type: Array, default: ['defaults']
        define_attribute :dump, type: Integer, default: 0
        define_attribute :pass, type: Integer, default: 0

        self.available_actions = [:present, :absent]
      end
    end
  end
end
