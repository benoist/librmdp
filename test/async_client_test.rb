require 'test_helper'

class TestClient < MiniTest::Unit::TestCase

  def setup
    @client = Majordomo::AsyncClient.new(Majordomo::Config.new)
  end

  def test_connect_to_broker
    @client.connect_to_broker
    assert_kind_of ZMQ::Socket, @client.client

    old_client = @client.client.dup
    @client.connect_to_broker
    refute_equal old_client, @client.client
  end

end
