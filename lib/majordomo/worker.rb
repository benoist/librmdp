module Majordomo
  class Worker
    attr_accessor :broker, :service, :worker, :heartbeat_at, :heartbeat, :liveness, :reconnect

    # @param [Majordomo::Config] config
    def initialize(config, service, context = ZMQ::Context.new)
      @config  = config
      @context = context
      @poller  = ZMQ::Poller.new
      @service = service

      @heartbeat = @config.heartbeat_interval
      @reconnect = @config.heartbeat_liveness
      connect_to_broker

      trap(:INT) { exit }
      at_exit { destroy }
    end

    def logger
      @config.logger
    end

    def destroy
      @worker.close
      @context.terminate
    end

    def connect_to_broker
      if @worker
        logger.debug 'Closing connection to broker'
        @poller.deregister(@worker, ZMQ::POLLIN)
        @worker.close
      end
      @worker = @context.socket(ZMQ::DEALER)
      @worker.connect(@config.broker_endpoint)
      @worker.setsockopt(ZMQ::LINGER, 0)
      @poller.register(@worker, ZMQ::POLLIN)
      @liveness     = @config.heartbeat_liveness
      @heartbeat_at = Time.now + 0.001 * @heartbeat

      logger.debug 'Sending READY to broker'
      send_to_broker(READY, [@service])
    end

    def send_to_broker(command, message = [])
      message.unshift(command)
      message.unshift(WORKER)
      message.unshift('')

      worker.send_strings(message)
    end

    def receive_message(reply_to)
      loop do
        items = @poller.poll(@heartbeat)
        if items > 0
          @worker.recv_strings(message = [])

          @liveness = @config.heartbeat_liveness
          message.shift
          header = message.shift
          raise unless header == WORKER

          command = message.shift
          case command
            when REQUEST
              logger.debug 'REQUEST from broker'
              reply_to << message.shift
              message.shift
              return message
            when HEARTBEAT
              #
            when DISCONNECT
              logger.debug 'DISCONNECT from broker'
              connect_to_broker
            else
              raise
          end
        elsif (@liveness -= 1) == 0
          sleep(@reconnect*0.001)
          connect_to_broker
        end

        if Time.now > @heartbeat_at
          send_to_broker(HEARTBEAT)
        end
      end
    end

    def send_message(report, reply_to)
      logger.debug 'Sending REPLY to broker'
      report.unshift('')
      report.unshift(reply_to)
      send_to_broker(REPLY, report)
    end
  end
end
