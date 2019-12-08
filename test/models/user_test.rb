require 'test_helper'
require 'argon2'

class UserTest < ActiveSupport::TestCase
  test "hashes work correctly" do
    User.all.each do |x|
      assert_equal true, Argon2::Password.verify_password('test', x.password)
    end
  end
end
