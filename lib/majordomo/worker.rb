module Majordomo
  class Worker
    attr_accessor :broker, :service, :worker, :heartbeat_at, :heartbeat, :liveness, :reconnect

    def initialize(broker, service, context = ZMQ::Context.new)
      @context = context
      @poller  = ZMQ::Poller.new
      @broker  = broker
      @service = service

      @heartbeat = HEARTBEAT_INTERVAL
      @reconnect = HEARTBEAT_INTERVAL
      connect_to_broker

      trap(:INT) { exit }
      at_exit { destroy }
    end

    def destroy
      @worker.close
      @context.terminate
    end

    def connect_to_broker
      if @worker
        puts 'Closing connection to broker'
        @poller.deregister(@worker, ZMQ::POLLIN)
        @worker.close
      end
      @worker = @context.socket(ZMQ::DEALER)
      @worker.connect(@broker)
      @worker.setsockopt(ZMQ::LINGER, 0)
      @poller.register(@worker, ZMQ::POLLIN)

      send_to_broker(READY, [@service])
      @liveness     = HEARTBEAT_LIVENESS
      @heartbeat_at = Time.now + 0.001 * @heartbeat
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

          @liveness = HEARTBEAT_LIVENESS
          message.shift
          header = message.shift
          raise unless header == WORKER

          command = message.shift
          case command
            when REQUEST
              reply_to << message.shift
              message.shift
              return message
            when HEARTBEAT
            # Do nothing
            when DISCONNECT
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
      report.unshift('')
      report.unshift(reply_to)
      send_to_broker(REPLY, report)
    end
  end
end
