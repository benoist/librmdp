require 'test_helper'

class TestIntegration < MiniTest::Unit::TestCase
  def setup
    @threads                  = []
    Thread.abort_on_exception = true
  end

  def start_broker
    @threads << Thread.new do
      Majordomo::Broker.new(Majordomo::Config.new).mediate
    end
  end

  def start_worker
    @threads << Thread.new do
      worker = Majordomo::Worker.new(Majordomo::Config.new, 'echo')

      request = worker.receive_message(reply_to = '')
      worker.send_message(request, reply_to)
      Thread.current.terminate
    end
  end

  def close_threads
    @threads.each { |thread| thread.exit }
    @threads = []
  end

  def test_round_trip
    start_broker
    start_worker

    client = Majordomo::AsyncClient.new(Majordomo::Config.new)
    client.send_message('echo', 'a')

    assert_equal %w(a), client.receive_message

    close_threads
  end

end





