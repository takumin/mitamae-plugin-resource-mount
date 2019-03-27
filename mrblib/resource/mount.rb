module ::MItamae
  module Plugin
    module Resource
      class Mount < ::MItamae::Resource::Base
        define_attribute :action, default: :mount
        define_attribute :device, type: String, required: true
        define_attribute :point, type: String, default_name: true
        define_attribute :type, type: String, required: true
        define_attribute :options, type: Array, required: true
        define_attribute :dump, type: Integer, default: 0
        define_attribute :pass, type: Integer, default: 0
        define_attribute :fstab, type: [TrueClass, FalseClass], default: false

        self.available_actions = [:mount, :unmount]
      end
    end
  end
end
