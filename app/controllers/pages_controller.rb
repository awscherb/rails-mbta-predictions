require 'net/http'
require 'json'

class PagesController < ApplicationController

  API_KEY = File.read("/home/alex/rails/rails-mbta-predictions/key").strip! 
 
  # get all the routes
  def home
    uri = URI("http://realtime.mbta.com/developer/api/v2/routes?api_key="+API_KEY+"&format=json")
    routes_json = JSON.parse Net::HTTP.get uri
    @route_hash = {}
    @routes = []
    unless !routes_json['mode']
      routes_json['mode'].each do |mode|
        mode['route'].each do |route|
          unless mode['route_type'] == "2" or mode['route_type'] == "4"
            @routes << route['route_name']
            @route_hash[route['route_name']] = route['route_id']
          end
        end
      end
    end
  end

  # get the stops for a route
  def stops
    @stops = []
    @stops_hash = {}
    @route_id = params[:id]
    uri = URI("http://realtime.mbta.com/developer/api/v2/"\
              "stopsbyroute?api_key="+API_KEY+"&route="\
              +@route_id+"&format=json")
    sr = Net::HTTP.get uri
    s = JSON.parse sr
    s['direction'].each do |direction| direction['stop'].each do |stop|
      unless stop['parent_station_name'].empty?
        @stops << stop['parent_station_name']
        @stops_hash[stop['parent_station_name']] = stop['parent_station']
      else
        @stops << stop['stop_name']
        @stops_hash[stop['stop_name']] = stop['stop_id']
      end
     end
    end
    @stops = @stops.uniq
    @stops = @stops.sort
  end

  # get predictions
  def predictions
    puts Dir.pwd
    @route = params[:route]
    @stop = params[:stop]
    @directions = {}
    @predictions_table = {} 
    uri = URI("http://realtime.mbta.com/developer/api/v2/"\
              "predictionsbystop?api_key="+API_KEY+"&stop="\
              +@stop+"&format=json")
    pr = Net::HTTP.get uri
    p = JSON.parse pr
    
    @stop_name = p['stop_name']
    if not p['mode'] then return end
    p['mode'].each do |mode|
      mode['route'].each do |route|
        if route['route_id'] == @route
          route['direction'].each do |direction|
            @directions[direction['direction_name']] = ''
            @predictions_table[direction['direction_name']] = []
            direction['trip'].each do |trip|
              @directions[direction['direction_name']] = direction['direction_name']
              @predictions_table[direction['direction_name']] \
                << "arriving in " + Time.at(trip['pre_away'].to_i).strftime("%M:%S") \
                + " to " + trip['trip_headsign']
            end
          end
        end
      end
    end
   @predictions_table.keys.each do |direction|
     @predictions_table[direction].sort!
   end 
  end
  
  # get url for 'route' page
  def route_url route_id, route_name
    return 'route?id=' + route_id
  end

  # get url for predictions at stop
  def predictions_url stop, route
    return '/predictions?stop=' + stop + '&route=' + CGI::escape(route)
  end

  helper_method :route_url
  helper_method :predictions_url
 
end
