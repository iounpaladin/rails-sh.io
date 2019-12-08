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
      t.boolean :ended

      t.timestamps
    end
  end
end
