class CreateBanks < ActiveRecord::Migration
  def change
    create_table :banks do |t|
      t.string :name
      t.string :address
      t.string :contact
      t.string :phone
      t.string :program
      t.string :city
      t.string :state
      t.integer :zip
      t.string :days
      t.string :distance
      t.float :lat
      t.float :lng
      #t.string :location
      t.timestamps null: false  
    end   
  end
end
