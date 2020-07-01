require_relative '../../lib/scraper_module'
require_relative '../../lib/mapping_module'

class AdminsController < ApplicationController
    include Scraper  
    include Mapping  

    get '/admin' do
        "In admin page"
        #binding.pry
    end 
    
    helpers do
        def scrape_to_db
           #This will have to be launchable from the admin page (not just via binding.pry) so that DB can be populated online
           #Runs scraper and populates the db
           banks = scrape_banks
           banks.each do |bank|
             Bank.create(name: bank[:name], address: bank[:address], contact: bank[:contact], phone: bank[:phone], program: bank[:program], city: bank[:city], state: bank[:state], zip: bank[:zip], days: bank[:days], distance: bank[:distance], lat: bank[:lat], lng: bank[:lng])
           end
           puts "scrape to db complete"
        end  
    end
end