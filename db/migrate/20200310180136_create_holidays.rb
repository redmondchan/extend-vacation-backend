class CreateHolidays < ActiveRecord::Migration[5.2]
  def change
    create_table :holidays do |t|
      t.integer :year_id
      t.string :name
      t.integer :year
      t.integer :day
      t.integer :month

      t.timestamps
    end
  end
end
