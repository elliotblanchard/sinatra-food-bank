require_relative '../../lib/mapping_module'
require './config/environment'
require 'date'
require 'active_support/time'

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
  
    @time = Bank.create_time_hash(params)
    same_time = Bank.find_by_time(@time)
    
    if same_time.length > 0
      # If address params are blank/nill (because user typed in address and didn't use the Google Maps selected auto-complete) 
      # (Or picked a saved / suggested address that their phone saved, which also skips Google Maps auto-complete)
      # Use the info the user input (they have to input something b/c it's a required form field)
      if (params[:street_number] == nil) && (params[:route] == nil) && (params[:postal_code] == nil)
        full_address = params[:address_input] + " New York, NY"
      else  
        full_address = params[:street_number] + " " + params[:route] + " New York, NY " + params[:postal_code]
      end

      # Get distance between the user and every food bank open at the right time / day
      @user_location = Mapping.get_location(full_address)
      @banks_sorted = Mapping.get_distance(full_address,same_time,@user_location)
      @api_key =  ENV['GOOGLE_MAPS_API_KEY']
      
      # Format open times correctly
      @banks_sorted.each do |bank|
        days_array = bank.days.gsub(/"/, "")[1..-2].split(',') #Clean out everything except letters, numbers, :, -, comma, and whitespace
        bank.days = ""
        days_array.each_with_index do |day, index|
          if day.length > 7 #Covers 'closed' or '-'
            day_detail = ""
            case index
              when 0
                day_detail = "Sun "
              when 1
                day_detail = "Mon "
              when 2
                day_detail = "Tue "
              when 3
                day_detail = "Wed "
              when 4
                day_detail = "Thu " 
              when 5
                day_detail = "Fri "
              else
                day_detail = "Sat " 
            end
            day_detail += day
            day_detail += ","
            bank.days << day_detail
          end
        end
      end
    end

    #Log search data
    Log.create(address: full_address, time: DateTime.now.in_time_zone('US/Eastern'))

    erb:'/show'
  end

  get "/style_test" do
    erb:'/style_test'
  end
end
