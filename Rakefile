require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'active_record'

namespace :db do

  task :parse_config do
    YAML::load(File.open('config/database.yml'))[settings.environment.to_s].each do |key, value|
      set "db_#{key}".to_sym, value
    end
  end

  task :establish_base_connection => [:parse_config] do
    ActiveRecord::Base.establish_connection(
      adapter: settings.db_adapter,
      host: settings.db_host,
      username: settings.db_username,
      password: settings.db_password
    )
  end

  task :establish_specific_connection => [:parse_config] do
    ActiveRecord::Base.establish_connection(
      adapter: settings.db_adapter,
      host: settings.db_host,
      database: settings.db_database,
      username: settings.db_username,
      password: settings.db_password
    )
  end

  desc "Create the database"
  task :create => [:establish_base_connection] do
    puts "Creating database #{settings.db_database}"

    ActiveRecord::Base.connection.create_database(settings.db_database)
  end

  desc "Drop the database"
  task :drop => [:establish_base_connection] do
    puts "Destroying database #{settings.db_database}"

    ActiveRecord::Base.connection.drop_database(settings.db_database)
  end

  desc "Create the database, load the schema, and initialize with the seed data"
  task :setup => [:create, :establish_specific_connection] do
    puts "Importing data into the database..."

    sh "mysql -u#{settings.db_username} -p#{settings.db_password} #{settings.db_database} < db/mysql_sql.txt"
  end
end

