require 'json'
require 'rest-client'
require 'net/http'
require 'launchy'
require 'nokogiri'

api_key = nil
begin
  api_key = File.read('.api_key').chomp
rescue
  puts "Unable to read '.api_key'. Please provide a valid Google API key."
  exit
end

geolocation_string = RestClient.get("http://maps.googleapis.com/maps/api/geocode/json?&address=1061+Market+Street+San+Francisco+CA+94102&sensor=false")
@origin = JSON.parse(geolocation_string)

def geolocation_parser(geo_info)
  coords_hash = geo_info["results"][0]["geometry"]["location"]
  latitude = coords_hash["lat"]
  longitude = coords_hash["lng"]
  latitude.to_s + "," + longitude.to_s
end


places_url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?"
places_url += "&key=" + api_key
places_url += "&location=" + geolocation_parser(@origin)
places_url += "&sensor=false"
places_url += "&keyword=ice+cream"
places_url += "&opennow"
places_url += "&rankby=distance"

places_string = RestClient.get(places_url)

parsed_places = JSON.parse(places_string)

def places_coordinates(parsed_places)
  coordinates_hashes = parsed_places["results"].map do |result|
    name = result["name"]
    location = result["geometry"]["location"].values.join(',')
    [name, location]
  end
end

def get_directions(place)
  directions_url = "https://maps.googleapis.com/maps/api/directions/json?"
  directions_url += "&origin=" + geolocation_parser(@origin)
  directions_url += "&destination=" + place
  directions_url += "&sensor=false"
end

places_coordinates(parsed_places).each do | place |

  parsed_directions = JSON.parse(RestClient.get(get_directions(place[1])))
  puts place[0]
  parsed_steps = parsed_directions["routes"][0]["legs"][0]["steps"]

  parsed_steps.each_with_index do | step, number |
    puts (number + 1).to_s + ". " + Nokogiri::HTML(step["html_instructions"]).text
  end

  puts "_________________________________________________________________"
end



