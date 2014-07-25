require 'rubygems'
require 'bundler/setup'

require 'json'

require 'sinatra'
require "sinatra/reloader" if development?
require 'active_record'
require 'logger'

require 'rack/contrib/jsonp'

use Rack::JSONP

ActiveRecord::Base.logger = Logger.new(STDOUT) if development?
ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'] || 'postgres://localhost/postalcodes_development')
ActiveRecord::Base.connection.enable_query_cache!

class Postcode < ActiveRecord::Base
  self.table_name = "postcode"
end

before do
  content_type :json
end

get '/search/:code' do |code|
  halt 422, { :error => "Not correct format, it should be like 7557AC" }.to_json if !code[/[0-9]{4}[a-zA-Z]{2}/]
  begin
    postcode = Postcode.find_by_postcode!(code.upcase)
    [{ street: postcode.street, zip: "#{postcode.pnum} #{postcode.pchar}", city: postcode.city }].to_json
  rescue ActiveRecord::RecordNotFound
    halt 404, { :error => "Route not found" }.to_json
  end
end

get '/*' do
  status 404
  { :error => "Route not found" }.to_json
end
