# frozen_string_literal: true

class Object
  def self.const_missing(name)
    app = Monq::App.instance if defined?(Monq::App)
    if app&.environments
      app.environments.each do |env|
        mod = env.namespace_module
        return mod.const_get(name) if mod.const_defined?(name, false)
      end
    end
    super
  end
end
