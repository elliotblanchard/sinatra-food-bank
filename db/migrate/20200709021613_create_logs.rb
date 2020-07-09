class CreateLogs < ActiveRecord::Migration
  def change
    create_table :logs do |t|
      t.string :address
      t.string :time
      t.timestamps null: false  
    end    
  end
end
