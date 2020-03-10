class CreateResults < ActiveRecord::Migration[5.2]
  def change
    create_table :results do |t|
      t.integer :year_id
      t.integer :pto
      t.string  :result

      t.timestamps
    end
  end
end
