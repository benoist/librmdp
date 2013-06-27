module Majordomo
  class Client
    attr_accessor :timeout, :client

    def initialize(broker, context = ZMQ::Context.new)
      @context = context
      @poller  = ZMQ::Poller.new
      @broker  = broker

      @timeout = 2500

      connect_to_broker
    end

    def connect_to_broker
      if @client
        @poller.deregister(@client, ZMQ::POLLIN)
        @client.close
      end
      @client = @context.socket(ZMQ::DEALER)
      @client.connect(@broker)
      @poller.register(@client, ZMQ::POLLIN)
    end

    def send_message(service, request)
      request = [request] unless request.is_a?(Array)
      request.unshift(service)
      request.unshift(CLIENT)
      request.unshift('')
      @client.send_strings(request)
    end

    def receive_message
      @client.recv_strings(message = [])
      message.shift
      header = message.shift
      raise unless header == CLIENT

      message.shift #service

      message
    end
  end
end
