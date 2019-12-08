require 'test_helper'

class MessageTest < ActiveSupport::TestCase
  test "action cable for messages works" do
    assert_equal false, ActionCable.server.nil?
  end
end
