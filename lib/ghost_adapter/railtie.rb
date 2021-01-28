require 'rails'

module GhostAdapter
  class Railtie < Rails::Railtie
    config.ghost_adapter = ActiveSupport::OrderedOptions.new

    initializer 'ghost_adapter.configure' do |app|
      GhostAdapter.configure(app.config.ghost_adapter.to_h)
    end

    initializer 'ghost_adapter.second_configure' do |_app|
      puts GhostAdapter.config.compact
    end
  end
end
