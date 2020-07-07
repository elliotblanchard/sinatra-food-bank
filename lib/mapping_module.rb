module Mapping
  
    def self.check_address(address)
      # Confirms address user entered exists
      Dotenv.load('.env') #Loads the API key using the Dotenv GEM - you must re-create the .env file in root directory
      Geokit::Geocoders::GoogleGeocoder.api_key = ENV['GOOGLE_API_KEY']
      
      location = Geokit::Geocoders::GoogleGeocoder.geocode address
      
      if location.street_address == "" || location.street_address == nil  || location.street_name == "" || location.street_name == nil || location.street_number == "" || location.street_number == nil
        return false
      else
        return location.city
      end
    end
    
    def self.get_distance(user_address,banks,user_location)
      # Return array of food banks sorted by distance

      #user_location = self.get_location(user_address)
      
      puts "Looking up distances "
      
      # First get distances for each of the food banks
      banks.each_with_index do |bank, index|
        #banks[index].distance = user_location.distance_to(banks[index].location) # Important line that calculates distance in miles between user and food bank
        bankLatLng = Geokit::LatLng.new
        bankLatLng.lat = banks[index].lat
        bankLatLng.lng = banks[index].lng
        banks[index].distance = user_location.distance_to(bankLatLng) # Important line that calculates distance in miles between user and food bank        
        print "\b\b\b\b" 
        percent_complete = (index.to_f+1.0)/banks.length.to_f # This is basically instantaneous now
        print "#{(percent_complete.round(2)*100).to_i}%"
      end
      
      puts "\n"
      banks_sorted = banks.sort_by { |bank| bank.distance.to_f }
      banks_sorted
    end
    
    def self.get_location(address)
      #Returns a location object of a street address using Geokit and the Google API
      Dotenv.load('.env') #Loads the API key
      Geokit::Geocoders::GoogleGeocoder.api_key = ENV['GOOGLE_API_KEY'] #Loads the API key using the Dotenv GEM - you must re-create the .env file in root directory
      
      Geokit::Geocoders::GoogleGeocoder.geocode address
    end
  end