class Bank < ActiveRecord::Base

    def self.create_time_hash(params)
      @time = {}
      date_elements = Array.new
      time_elements = Array.new
  
      if params[:date].include? "-"
        #Browser supports date field
        date_elements = params[:date].split("-")
      elsif (params[:date].include? "/") && (params[:date].split("/").length == 3) 
        #Browser does not support date field 
        if (params[:date].split("/")[0].to_i > 0) && (params[:date].split("/")[0].to_i < 13) && (params[:date].split("/")[1].to_i > 0) && (params[:date].split("/")[1].to_i < 32) && (params[:date].split("/")[2][-2..-1].to_i > -1) && (params[:date].split("/")[2][-2..-1].to_i < 99)
          #is valid input
          temp_elements = params[:date].split("/")
          date_elements[0] = temp_elements[2]
          date_elements[1] = temp_elements[0]
          date_elements[2] = temp_elements[1]  
        else
          #Default to today
          date_elements[0] = DateTime.now.in_time_zone('US/Eastern').year
          date_elements[1] = DateTime.now.in_time_zone('US/Eastern').month
          date_elements[2] = DateTime.now.in_time_zone('US/Eastern').day 
        end
      else
        #Default to today
        date_elements[0] = DateTime.now.in_time_zone('US/Eastern').year
        date_elements[1] = DateTime.now.in_time_zone('US/Eastern').month
        date_elements[2] = DateTime.now.in_time_zone('US/Eastern').day    
      end
      #Set up time
      if (!params[:time].include? "M") && (params[:time].split(":").length == 2)
        #Browser supports time field
        time_elements = params[:time].split(":")
      elsif (params[:time].split(":").length == 2) && ((params[:time].include? "AM") || (params[:time].include? "PM")) 
        #Browser does not support time field
        temp_elements = params[:time].gsub(/[a-zA-Z][a-zA-Z]/, "").split(":") #Remove AM/PM and whitespace before split
        if params[:time].include? "AM"
          time_elements[0] = temp_elements[0]
        else
          time_elements[0] = temp_elements[0].to_i + 12
        end
        time_elements[1] = temp_elements[1]
      else
        #Default to now
        time_elements[0] = DateTime.now.in_time_zone('US/Eastern').hour
        time_elements[1] = DateTime.now.in_time_zone('US/Eastern').min
      end
      
      # This catches an invalid date
      begin
        dateTime = DateTime.new(date_elements[0].to_i,date_elements[1].to_i,date_elements[2].to_i,time_elements[0].to_i,time_elements[1].to_i)
      rescue ArgumentError
        # handle invalid date / time / garbage input
        dateTime = DateTime.now.in_time_zone('US/Eastern')
      end
      
      @time[:day] = dateTime.strftime("%w") #Returns day of week as number starting with Sunday = 0
      #@day_of_week = dateTime.strftime("%A")
      @time[:day_of_week] = dateTime.strftime("%A")
      @time[:hour] = dateTime.strftime("%l") #Hour of the day, 12 hour format, blank padded as in " 1" instead of "01"
      @time[:minutes] = dateTime.strftime("%M") #Minute of the hour zero padded as in "05"
      @time[:ampm] = dateTime.strftime("%p") #AM/PM

      return @time
    end

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
          if bank.days
            if bank.days.split(",")[time_hash[:day].to_i].include? "-"
              time_raw = bank.days.split(",")[time_hash[:day].to_i].split("-")
            else
              # rare entries are formatted "12:00 PM to 02:00 PM" instead of "12:00 PM - 02:00 PM"
              time_raw = bank.days.split(",")[time_hash[:day].to_i].split("to") 
            end
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
          if time_hash[:hour].to_i == 12
            time = Time.new(2020, 1, 1, 0, time_hash[:minutes])
          else
            time = Time.new(2020, 1, 1, time_hash[:hour], time_hash[:minutes])
          end
        else
          if time_hash[:hour].to_i == 12
            adjusted_hour = 12
          else 
            adjusted_hour = time_hash[:hour].to_i+12
          end
          time = Time.new(2020, 1, 1, adjusted_hour, time_hash[:minutes])
        end
        time
      end
end
