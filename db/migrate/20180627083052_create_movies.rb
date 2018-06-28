class CreateMovies < ActiveRecord::Migration[5.2]
  def change
    create_table :movies do |t|
      t.string :title
      t.text :description
      t.string :image_url
      t.integer :kinokz_id
    end
  end
end
