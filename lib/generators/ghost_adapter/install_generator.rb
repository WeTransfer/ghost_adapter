module GhostAdapter
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc 'Copy ghost_adapter_setup rakefile for automatic ghost migration'
      source_root File.expand_path('templates', __dir__)

      def copy_task
        template 'ghost_adapter_setup.rake', 'lib/tasks/ghost_adapter_setup.rake'
      end
    end
  end
end
