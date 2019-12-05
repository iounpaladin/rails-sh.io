class CreateGames < ActiveRecord::Migration[5.0]
  def change
    create_table :games do |t|
      t.string :title
      t.boolean :libswon
      t.string :winmethod
      t.integer :playercount
      t.text :players
      t.text :turns

      t.timestamps
    end
  end
end
