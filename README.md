# Foodspotting Simple Spotter #


## Introduction ## 

This is a Sinatra application that will authenticate, view and post sightings to Foodspotting using the v1 rest API

Get familiar with the Foodspotting v1 API documentation

http://www.foodspotting.com/api


## Usage ##

Register your application to get an API Key

http://www.fooodspotting.com/apps/new

Local application url: http://localhost:4567
Local callback url: http://localhost:4567/callback


Add your API key & secret to simple_spotter.rb

  API_KEY = '<YOUR_KEY>'
  API_SECRET = '<YOUR_SECRET>'


Install Sinatra

  sudo gem install sinatra


Run the sinatra app

  ruby simple_spotter.rb


Open http://localhost:4567 in your favorite browser