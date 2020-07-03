require './config/environment'
require 'date'

class ApplicationController < Sinatra::Base

  configure do
    set :public_folder, 'public'
    set :views, 'app/views'
    enable :sessions
    register Sinatra::Flash
    # !!! isn't this session secret insecure b/c it is on github?
    set :session_secret, "3t6w9z$C&F)H@McQfTjWnZr4u7x!A%D*G-KaNdRgUkXp2s5v8y/B?E(H+MbQeShV"
  end

  get "/" do
    #Loads the API key for the map 
    Dotenv.load('.env') 
    @api_key =  ENV['GOOGLE_MAPS_API_KEY']  
    #Uses the Google Places API for address auto-complete - example here:
    #https://developers.google.com/maps/documentation/javascript/examples/places-autocomplete-addressform
    erb :welcome
  end

  post "/" do
    #
    #
    # CLI find banks code for reference:
    #  def find_banks
    #    #Find food banks open at the right time
    #    same_time = FoodBank::Bank.find_by_time(@time)
    #    if same_time.length > 0
    #      # Get distance between the user and every food bank open at the right time / day
    #      banks_sorted = FoodBank::Mapping.get_distance(@user_address,same_time)
    #    end
    #    banks_sorted
    #  end
    #
    #
    # !!! Need to handle case where DATE and TIME is not supported by browser
    # !!! Still need to check address - think there's some sort of "certainty" field in the GeoKit response you can look at
    #
    #
    # First task: create the correct time hash from params to send to Bank.find_by_time(time_hash)
    # You are going to have to have two cases - one for browsers that support DATE / TIME fields, and one for those that don't
    #
    #
    # CLI time hash code:
    # @time = {}
    # @days = ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday']
    # @time[:day] = input-1
    # @time[:hour] = time_elements[0]
    # @time[:minutes] = minutes
    # @time[:ampm] = ampm
    #
    # Example params when using a brower that supports both DATE and TIME fields (like Chrome)
    #   {"street_number"=>"45", "route"=>"Waverly Avenue", "locality"=>"", 
    #    "administrative_area_level_1"=>"NY", "postal_code"=>"11205","country"=>"United States",
    #    "date"=>"2020-07-02","time"=>"12:02"}
    # Getting the day of week from a Date class object: https://stackoverflow.com/questions/4044574/how-can-i-calculate-the-day-of-the-week-of-a-date-in-ruby
    # Creating a Date object: https://ruby-doc.org/stdlib-2.6.5/libdoc/date/rdoc/Date.html#method-i-strftime
    # %w - Day of the week (Sunday is 0, 0..6)
    #binding.pry
    time = {}
    date_elements = params[:date].split("-")
    time_elements = params[:time].split(":")
    dateTime = DateTime.new(date_elements[0].to_i,date_elements[1].to_i,date_elements[2].to_i,time_elements[0].to_i,time_elements[1].to_i)
    time[:day] = dateTime.strftime("%w") #Returns day of week as number starting with Sunday = 0
    time[:hour] = dateTime.strftime("%l") #Hour of the day, 12 hour format, blank padded as in " 1" instead of "01"
    time[:minutes] = dateTime.strftime("%M") #Minute of the hour zero padded as in "05"
    time[:ampm] = dateTime.strftime("%p") #AM/PM
    #Now that you have the time hash, need to send it to Bank.find_by_time(time_hash)

  end
end
