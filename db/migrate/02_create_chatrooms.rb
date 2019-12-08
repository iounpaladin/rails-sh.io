class CreateChatrooms < ActiveRecord::Migration[5.0]
  def change
    create_table :chatrooms do |t|
      t.string :topic

      t.integer :faspolicies
      t.integer :libpolicies
      t.boolean :started
      t.string :deck, array: true
      t.string :discard, array: true
      t.string :players, array: true
      t.string :fasboard, array: true
      t.string :roles, array: true
      t.string :votes, array: true
      t.boolean :ended
      t.boolean :needsvotes
      t.string :draw, array: true

      t.integer :president
      t.integer :chancellor
      t.integer :tracker
      t.integer :prescut
      t.integer :chanccut

      t.timestamps
    end
  end
end
