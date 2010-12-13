require 'rubygems'
require 'sinatra'
require 'json'
require 'net/http'
require 'uri'
require 'oauth'
require 'pp'

enable :sessions

API_KEY = ''
API_SECRET = ''

before do
  @consumer = OAuth::Consumer.new(API_KEY, API_SECRET, :site => Foodspotting::SITE_URL)
end

get '/' do
  @sightings = Foodspotting.recent_sightings || []
  
  if session['access_token']
    @wanted = Foodspotting.wanted_sightings(session['access_token'])
  else
    @wanted = []
  end
  haml :index
end

post '/spot' do
  # Just forward the post_body we got from the form directly to Foodspotting
  @review = Foodspotting.spot(request.body.string, session['access_token'], request.content_type)
  haml :spot
end

get '/login' do
  session['request_token'] = @consumer.get_request_token
  redirect session['request_token'].authorize_url
end

get '/logout' do
  session['access_token'] = nil
  session['user'] = nil
  redirect '/'
end

get '/callback' do
  session['access_token'] = session['request_token'].get_access_token(:oauth_verifier => params['oauth_verifier'])
  session['request_token'] = nil
  session['user'] = Foodspotting.logged_in_user(session['access_token'])
  redirect '/'
end

class Foodspotting
  SITE_URL = 'http://localhost:3000'
  API_URL = 'http://localhost:3000/api'
  
  def self.recent_sightings
    uri = URI.parse("#{API_URL}/sightings.json")
    res = Net::HTTP.get_response(uri)
    JSON.parse(res.body)
  end

  def self.logged_in_user(access_token)
    uri = "#{API_URL}/people/current.json"
    res = access_token.get(uri)
    JSON.parse(res.body)
  end

  def self.wanted_sightings(access_token)
    uri = "#{API_URL}/sightings.json?filter=wanted"
    res = access_token.get(uri)
    JSON.parse(res.body)
  end
  
  def self.spot(post_body, access_token, content_type)
    uri = "#{API_URL}/reviews.json"
    res = access_token.post(uri, post_body, {'Content-Type' => content_type})
    JSON.parse(res.body)
  end
  
end