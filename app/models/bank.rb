class Bank < ActiveRecord::Base

    def self.find_by_time(time_hash)
        # Get food banks that are open on the correct day - looks for 'M' as in 'AM' or 'PM' to determine if bank is open
        #correct_day = self.all.select {|a| a.days[time_hash[:day]].include? "M"}
        correct_day =[]
        self.all.each do |a| 
          if a.days 
            if a.days.split(",")[time_hash[:day].to_i].include? "M"
              correct_day << a
            end
          end
        end

        # Create a time object from the user requested time
        user_time = self.create_time_object(time_hash)
        
        # This will be array of food banks that are open at the correct time AND day
        correct_time = []
        
        correct_day.each do |bank| 
          # Parse the time data in the XML file to extract times
          #time_raw = bank.days[time_hash[:day]].split("-")
          if bank.days
            time_raw = bank.days.split(",")[time_hash[:day].to_i].split("-")
          end
          start_time_raw = time_raw[0].split(":")
          start_time_raw[0] = start_time_raw[0].scan(/\d/).join('') #only take digits
          end_time_raw = time_raw[1].split(":")
          end_time_raw[1] = end_time_raw[1][0,5] #Trim edge case data
          
          # Create two hashes using the extracted data
          bank_time_start_hash = {
            :day => 0, 
            :hour => start_time_raw[0].strip.to_i, 
            :minutes => start_time_raw[1].strip[0,2].to_i, 
            :ampm => start_time_raw[1].strip[-2..]
          }
          
          bank_time_end_hash = {
            :day => 0, 
            :hour => end_time_raw[0].strip.to_i, 
            :minutes => end_time_raw[1].strip[0,2].to_i, 
            :ampm => end_time_raw[1][end_time_raw[1].index("M")-1,end_time_raw[1].index("M")]
          }
    
          # Create two time objects from the hashes
          bank_time_start = create_time_object(bank_time_start_hash)
          bank_time_end = create_time_object(bank_time_end_hash)
          
          #Checking if the user's time is in the open hours of the food bank
          range = bank_time_start..bank_time_end
          if range === user_time 
            correct_time << bank
          end
        end
        correct_time
      end
      
      def self.create_time_object(time_hash)
        # Quick method to create time objects
        if time_hash[:ampm] == "AM"
          time = Time.new(2020, 1, 1, time_hash[:hour], time_hash[:minutes])
        else
          if time_hash[:hour].to_i == 12
            adjusted_hour = 13
          else 
            adjusted_hour = time_hash[:hour].to_i+12
          end
          time = Time.new(2020, 1, 1, adjusted_hour, time_hash[:minutes])
        end
        time
      end
end
