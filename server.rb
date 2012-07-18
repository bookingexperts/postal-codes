require 'rubygems'
require 'bundler/setup'

require 'json'

require 'sinatra'
require "sinatra/reloader" if development?
require 'active_record'
require 'logger'

YAML::load(File.open('config/database.yml'))[settings.environment.to_s].each do |key, value|
  set "db_#{key}".to_sym, value
end

ActiveRecord::Base.logger = Logger.new(STDOUT) if development?
ActiveRecord::Base.establish_connection(
  adapter: settings.db_adapter,
  host: settings.db_host,
  database: settings.db_database,
  username: settings.db_username,
  password: settings.db_password
)

ActiveRecord::Base.connection.enable_query_cache!

class Postcode < ActiveRecord::Base
  self.table_name = "postcode"
  
  scope :search, lambda { |search| where("CAST(fourpp AS CHAR) LIKE '%#{search}%'") }

  belongs_to :city
end

class Street < ActiveRecord::Base
  self.table_name = "street"
  
  belongs_to :postcode
end

class City < ActiveRecord::Base
  self.table_name = "city"
  
  has_many :postcodes
  has_one :cityname
end

class Cityname < ActiveRecord::Base
  self.table_name = "cityname"
  
  belongs_to :city
end
  
get '/search/:code' do |code|
  content_type :json

  halt 422, { :error => "Search string too short" }.to_json unless code.length >= 4

  scanned_code=code.scan(/([a-zA-Z]{2})([0-9]{4})/)

  halt 422, { :error => "Wrong search string format" }.to_json if scanned_code.blank?
  
  postcodes=Postcode.search(scanned_code[0][1]).pluck(:id)
  streets=Street.where(:postcode_id => postcodes).where(:chars => scanned_code[0][0])

  addresses = []    

  streets.each do |street|
    addresses << { :street => street.street, :zip => "#{street.postcode.fourpp} #{street.chars}", :city => street.postcode.city.cityname.name }
  end

  addresses.to_json
end

get '/*' do
  content_type :json
  status 404
  { :error => "Route not found" }.to_json
end


