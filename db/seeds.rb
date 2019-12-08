# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
#
#

# this password is "test"
password = "$argon2id$v=19$m=65536,t=2,p=1$pdWiofusCFGj8Zjb/D7OEw$p9mW/VdMe7p0eI6htDvCftI+hdKQyP1wj97NZRROg/Q"
User.create!(:username => "paladin", :password => password, :elo => 1600, :role => "admin")
User.create!(:username => "tester1", :password => password, :elo => 1600, :role => "admin")
User.create!(:username => "tester2", :password => password, :elo => 1600, :role => "admin")
User.create!(:username => "tester3", :password => password, :elo => 1600, :role => "admin")
User.create!(:username => "tester4", :password => password, :elo => 1600, :role => "admin")
