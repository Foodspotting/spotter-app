require 'rubygems'
require 'sinatra'
require 'json'
require 'net/http'
require 'uri'
require 'cgi'
require 'pp'

enable :sessions

API_KEY = ''
API_SECRET = ''
REDIRECT_URI = 'http://localhost:4567/callback'

module Tubes
  def self.get(url, params = {}, headers = {})
    if params.keys.size > 0
      url = "#{url}?" + params.collect { |k,v| "#{k}=#{v}" } * '&'
    end
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Get.new(uri.request_uri, headers)
    http.request(req)
  end

  def self.post(url, params = {}, data = nil, headers = {})
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Post.new(uri.request_uri, headers)
    if data.nil?
      req.set_form_data(params)
    else
      req.set_form_data(data)
    end
    http.request(req)
  end
end

module OAuth2
  class Consumer
    def initialize(key, secret, provider_url, redirect_uri)
      @key = key
      @secret = secret
      @provider_url = provider_url
      @redirect_uri = redirect_uri
    end

    def authorization_url
      "#{@provider_url}/oauth/authorize?response_type=code&client_id=#{@key}&redirect_uri=#{@redirect_uri}"
    end

    def get_access_token(auth_code)
      res = Tubes::post("#{@provider_url}/oauth/token",
                        {'grant_type' => 'authorization_code',
                         'code' => auth_code,
                         'redirect_uri' => REDIRECT_URI,
                         'client_id' => @key,
                         'client_secret' => @secret})
      data = JSON.parse(res.body)
      data['access_token']
    end
  end
end

before do
  @consumer = OAuth2::Consumer.new(API_KEY, API_SECRET, Foodspotting::SITE_URL, REDIRECT_URI)
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
  redirect @consumer.authorization_url
end

get '/logout' do
  session['access_token'] = nil
  session['user'] = nil
  redirect '/'
end

get '/callback' do
  session['access_token'] = @consumer.get_access_token(params[:code])
  session['user'] = Foodspotting.logged_in_user(session['access_token'])
  redirect '/'
end

class Foodspotting
  SITE_URL = 'http://www.foodspotting.com'
  API_URL = 'http://www.foodspotting.com/api'

  def self.recent_sightings
    res = Tubes::get("#{API_URL}/sightings",
                     {'api_key' => API_KEY})
    JSON.parse(res.body)
  end

  def self.logged_in_user(access_token)
    res = Tubes::get("#{API_URL}/people/current",
                     {'api_key' => API_KEY, 'oauth_token' => access_token})
    JSON.parse(res.body)
  end

  def self.wanted_sightings(access_token)
    res = Tubes::get("#{API_URL}/sightings",
                     {'filter' => 'wanted', 'api_key' => API_KEY, 'oauth_token' => access_token})
    JSON.parse(res.body)
  end

  def self.spot(post_body, access_token, content_type)
    res = Tubes::post("#{API_URL}/reviews",
                      {'api_key' => API_KEY, 'oauth_token' => access_token},
                      post_body,
                      {'Content-Type' => content_type})
    JSON.parse(res.body)
  end
end
