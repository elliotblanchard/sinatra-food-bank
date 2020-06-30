require './config/environment'

if ActiveRecord::Migrator.needs_migration?
  raise 'Migrations are pending. Run `rake db:migrate` to resolve the issue.'
end

#Here is where other controllers are mounted

#In case any PATCH and DELETE is ever needed
#use RACK::MethodOverride

use AdminsController
run ApplicationController
