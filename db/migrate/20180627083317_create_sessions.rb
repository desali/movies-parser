class CreateSessions < ActiveRecord::Migration[5.2]
  def change
    create_table :sessions do |t|
      t.integer :movie_id
      t.integer :cinema_id
      t.boolean :open, default: true
      t.string :time
    end
  end
end
