require_relative '../../lib/mapping_module'
require './config/environment'
require 'date'

class ApplicationController < Sinatra::Base
  include Mapping  

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
    # !!! Need to handle case where DATE and TIME is not supported by browser
    # !!! Still need to check address - think there's some sort of "certainty" field in the GeoKit response you can look at
    # !!! Need to search around a two hour window of the chosen time
    # !!! Need to save to a logging DB
    #
    # Example params when using a brower that supports both DATE and TIME fields (like Chrome)
    #   {"street_number"=>"45", "route"=>"Waverly Avenue", "locality"=>"", 
    #    "administrative_area_level_1"=>"NY", "postal_code"=>"11205","country"=>"United States",
    #    "date"=>"2020-07-02","time"=>"12:02"}
    # Getting the day of week from a Date class object: https://stackoverflow.com/questions/4044574/how-can-i-calculate-the-day-of-the-week-of-a-date-in-ruby
    # Creating a Date object: https://ruby-doc.org/stdlib-2.6.5/libdoc/date/rdoc/Date.html#method-i-strftime
    # %w - Day of the week (Sunday is 0, 0..6)
    @time = {}
    date_elements = params[:date].split("-")
    time_elements = params[:time].split(":")
    dateTime = DateTime.new(date_elements[0].to_i,date_elements[1].to_i,date_elements[2].to_i,time_elements[0].to_i,time_elements[1].to_i)
    @time[:day] = dateTime.strftime("%w") #Returns day of week as number starting with Sunday = 0
    @day_of_week = dateTime.strftime("%A")
    @time[:hour] = dateTime.strftime("%l") #Hour of the day, 12 hour format, blank padded as in " 1" instead of "01"
    @time[:minutes] = dateTime.strftime("%M") #Minute of the hour zero padded as in "05"
    @time[:ampm] = dateTime.strftime("%p") #AM/PM
    same_time = Bank.find_by_time(@time)
    #This seems to be working, but check further that same_time has only banks that are open on right day of the week AND time
    if same_time.length > 0
      # Get distance between the user and every food bank open at the right time / day
      full_address = params[:street_number] + " " + params[:route] + " New York, NY " + params[:postal_code]
      @user_location = Mapping.get_location(full_address)
      @banks_sorted = Mapping.get_distance(full_address,same_time,@user_location)
      @api_key =  ENV['GOOGLE_MAPS_API_KEY']
      # Format open times correctly
      @banks_sorted.each do |bank|
        days_array = bank.days.gsub(/[^\d\w\s:,-]/, "").split(',') #Clean out everything except letters, numbers, :, -, comma, and whitespace
        bank.days = ""
        days_array.each_with_index do |day, index|
          if day.length > 7 #Covers 'closed' or '-'
            day_detail = ""
            case index
              when 0
                day_detail = "Sunday"
              when 1
                day_detail = "Monday"
              when 2
                day_detail = "Tuesday"
              when 3
                day_detail = "Wednesday"
              when 4
                day_detail = "Thursday"
              when 5
                day_detail = "Friday"
              else
                day_detail = "Saturday" 
            end
            day_detail += day
            day_detail += ","
            bank.days << day_detail
          end
        end
      end
    end
    erb:'/show'
  end
end
