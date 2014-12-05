module Majordomo
  class AsyncClient
    attr_accessor :timeout, :client, :logger

    # @param [Majordomo::Config] config
    def initialize(config, context = ZMQ::Context.new)
      @config  = config
      @context = context
      @poller  = ZMQ::Poller.new
      @broker  = config.broker_endpoint
      @logger  = ActiveSupport::Logger.new(STDOUT)

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

    def receive_message(timeout = 60)
      items = @poller.poll(timeout * 1000)
      if items > 0
        logger.debug "Broker has #{items} items"

        @client.recv_strings(message = [])
        message.shift
        header = message.shift
        raise unless header == CLIENT

        message.shift #service

        message
      else
        connect_to_broker
        raise Timeout.new('Client timed out, reconnected to broker')
      end
    end
  end
end
