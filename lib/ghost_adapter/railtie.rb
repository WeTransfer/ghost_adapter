require 'rails'

module GhostAdapter
  class Railtie < Rails::Railtie
    config.ghost_adapter = ActiveSupport::OrderedOptions.new

    initializer 'ghost_adapter.configure' do |app|
      GhostAdapter.setup(app.config.ghost_adapter.to_h)
    end
  end
end
