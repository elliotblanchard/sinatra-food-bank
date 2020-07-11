require_relative 'mapping_module'

module Scraper
    include Mapping 
    BASE_PATH = "fixtures/Food_Bank_For_NYC_Open_Members_as_of_71020.kml"  
    
    def scrape_banks
        xml = File.read(BASE_PATH)
        doc = Nokogiri::XML(xml)  
        
        banks = []
        
        puts "Looking up food bank locations: "
        
        doc.css("Placemark").each_with_index do |bank, index|
          days = []
          days[0] = bank.css("ExtendedData Data[name='Sunday']").text.strip
          days[1] = bank.css("ExtendedData Data[name='Monday']").text.strip
          days[2] = bank.css("ExtendedData Data[name='Tuesday']").text.strip
          days[3] = bank.css("ExtendedData Data[name='Wednesday']").text.strip
          days[4] = bank.css("ExtendedData Data[name='Thursday']").text.strip
          days[5] = bank.css("ExtendedData Data[name='Friday']").text.strip
          days[6] = bank.css("ExtendedData Data[name='Saturday']").text.strip

          location = Mapping.get_location(bank.css("address").text.strip) #Thru GeoKit via Google API
          
          banks[index] = {
            :name => bank.css("name").text.strip,
            :address => bank.css("address").text.strip,
            :contact => bank.css("ExtendedData Data[name='Contact']").text.strip,
            :phone => bank.css("ExtendedData Data[name='Phone']").text.strip,
            :program => bank.css("ExtendedData Data[name='Program Type']").text.strip,
            :city => bank.css("ExtendedData Data[name='City']").text.strip,
            :state => bank.css("ExtendedData Data[name='State']").text.strip,
            :zip => bank.css("ExtendedData Data[name='ZIP Code']").text.strip,
            :days => days,
            :distance => 0,
            :lat => location.lat,
            :lng => location.lng
            #:location => Mapping.get_location(bank.css("address").text.strip) #Thru GeoKit via Google API
          }
          print "\b\b\b\b" 
          percent_complete = (index.to_f+1.0)/doc.css("Placemark").length.to_f
          print "#{(percent_complete.round(2)*100).to_i}%"
        end
        puts "\n"
        
        banks
        
      end    
   
end