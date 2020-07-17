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

    #Date start
    #....................................
    #@time = {}
    #date_elements = Array.new
    #time_elements = Array.new
    #
    #if params[:date].include? "-"
      #Browser supports date field
    #  date_elements = params[:date].split("-")
    #elsif (params[:date].include? "/") && (params[:date].split("/").length == 3) 
      #Browser does not support date field 
    #  if (params[:date].split("/")[0].to_i > 0) && (params[:date].split("/")[0].to_i < 13) && (params[:date].split("/")[1].to_i > 0) && (params[:date].split("/")[1].to_i < 32) && (params[:date].split("/")[2][-2..-1].to_i > -1) && (params[:date].split("/")[2][-2..-1].to_i < 99)
    #    #is valid input
    #    temp_elements = params[:date].split("/")
    #    date_elements[0] = temp_elements[2]
    #    date_elements[1] = temp_elements[0]
    #    date_elements[2] = temp_elements[1]  
    #  else
        #Default to today
    #    date_elements[0] = DateTime.now.in_time_zone('US/Eastern').year
    #    date_elements[1] = DateTime.now.in_time_zone('US/Eastern').month
    #    date_elements[2] = DateTime.now.in_time_zone('US/Eastern').day 
    #  end
    #else
      #Default to today
    #  date_elements[0] = DateTime.now.in_time_zone('US/Eastern').year
    #  date_elements[1] = DateTime.now.in_time_zone('US/Eastern').month
    #  date_elements[2] = DateTime.now.in_time_zone('US/Eastern').day    
    #end
    #Set up time
    #if (!params[:time].include? "M") && (params[:time].split(":").length == 2)
      #Browser supports time field
    #  time_elements = params[:time].split(":")
    #elsif (params[:time].split(":").length == 2) && ((params[:time].include? "AM") || (params[:time].include? "PM")) 
      #Browser does not support time field
    #  temp_elements = params[:time].gsub(/[a-zA-Z][a-zA-Z]/, "").split(":") #Remove AM/PM and whitespace before split
    #  if params[:time].include? "AM"
    #    time_elements[0] = temp_elements[0]
    #  else
    #    time_elements[0] = temp_elements[0].to_i + 12
    #  end
    #  time_elements[1] = temp_elements[1]
    #else
      #Default to now
    #  time_elements[0] = DateTime.now.in_time_zone('US/Eastern').hour
    #  time_elements[1] = DateTime.now.in_time_zone('US/Eastern').min
    #end
    
    # This catches an invalid date
    #begin
    #  dateTime = DateTime.new(date_elements[0].to_i,date_elements[1].to_i,date_elements[2].to_i,time_elements[0].to_i,time_elements[1].to_i)
    #rescue ArgumentError
      # handle invalid date / time / garbage input
    #  dateTime = DateTime.now.in_time_zone('US/Eastern')
    #end
    
    #@time[:day] = dateTime.strftime("%w") #Returns day of week as number starting with Sunday = 0
    #@day_of_week = dateTime.strftime("%A")
    #@time[:hour] = dateTime.strftime("%l") #Hour of the day, 12 hour format, blank padded as in " 1" instead of "01"
    #@time[:minutes] = dateTime.strftime("%M") #Minute of the hour zero padded as in "05"
    #@time[:ampm] = dateTime.strftime("%p") #AM/PM
    #....................................  
    #Date end
  
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
