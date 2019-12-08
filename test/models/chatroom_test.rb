require 'test_helper'

class ChatroomTest < ActiveSupport::TestCase
  test "duplicate names do not add" do
    Chatroom.create! :topic => "test"
    begin
      Chatroom.create! :topic => "test"
      assert_equal 1, 0 # Test failed, did not throw
    rescue
      assert_equal 1, 1 # Test passed, it threw
    end
  end
end
