migration_tasks = %w[db:migrate db:migrate:up db:migrate:down db:migrate:reset db:migrate:redo db:rollback]

# Rails 6 supports multi-database setups
if defined?(Rails::Application) && Rails.version.split('.').first.to_i >= 6
  require 'active_record'

  databases = ActiveRecord::Tasks::DatabaseTasks.setup_initial_database_yaml

  # the db:migrate tasks each have a separate command for migrating a single database
  ActiveRecord::Tasks::DatabaseTasks.for_each(databases) do |spec_name|
    migration_tasks.concat(%w[db:migrate db:migrate:up db:migrate:down].map { |task| "#{task}:#{spec_name}" })
  end
end

migration_tasks.each do |task|
  Rake::Task[task].enhance([:ghost_adapter_exec])
end

task ghost_adapter_exec: :environment do
  GhostAdapter::Internal.enable_ghost_migration!
end
