require 'majordomo/broker/service'
require 'majordomo/broker/worker'

module Majordomo
  class Broker

    attr_accessor :workers, :waiting, :services, :socket

    # @param [Majordomo::Config] config
    def initialize(config, context = ZMQ::Context.new)
      @config       = config
      @context      = context
      @socket       = @context.socket(ZMQ::ROUTER)
      @poller       = ZMQ::Poller.new
      @services     = {}
      @workers      = {}
      @waiting      = []
      @heartbeat_at = Time.now + 0.001 * @config.heartbeat_interval

      @socket.bind(config.broker_endpoint)
      @poller.register(@socket, ZMQ::POLLIN)
      trap(:INT) { exit }
      at_exit { destroy }

      logger.debug "Broker is bound to: #{config.broker_endpoint}"
    end

    def logger
      @config.logger
    end

    def mediate
      logger.debug 'Broker is waiting for incoming messages'
      loop do
        items = @poller.poll(@config.heartbeat_interval)

        if items > 0
          @socket.recv_strings(message = [])
          sender = message.shift
          message.shift #empty
          header = message.shift
          case header
            when CLIENT
              message_client(sender, message)
            when WORKER
              message_worker(sender, message)
          end
        end

        if Time.now > @heartbeat_at
          purge
          waiting.each do |worker|
            worker.send_message(HEARTBEAT)
          end
          @heartbeat_at = Time.now + 0.001 * @config.heartbeat_interval
        end
      end
    end

    def destroy
      @socket.close
      @context.terminate
    end

    def bind(endpoint)
      @socket.bind(endpoint)
    end

    def message_worker(sender, message)
      command      = message.shift
      identity     = sender.unpack('H*').first
      worker_ready = !!@workers[identity]

      worker = Worker.require(self, sender)

      case command
        when READY
          if worker_ready
            logger.debug "Worker was already marked as ready. Sending DISCONNECT to worker #{identity}"
            worker.delete(true)
          else
            service        = message.shift
            worker.service = Service.require(self, service)
            @waiting << worker
            worker.service.waiting << worker
            worker.service.workers += 1
            worker.expires_at      = Time.now + 0.001 * @config.heartbeat_expiry
            logger.debug "Worker #{identity} for service #{worker.service.name} is ready"
            worker.service.dispatch
          end
        when REPLY
          if worker_ready
            client = message.shift
            logger.debug "Worker #{identity} has a reply for #{client.unpack('H*').first}"
            message.shift
            message.unshift(worker.service.name)
            message.unshift(CLIENT)
            message.unshift(nil)
            message.unshift(client)
            @socket.send_strings(message)
          else
            worker.delete(true)
          end
        when HEARTBEAT
          if worker_ready
            if @waiting.any?
              @waiting.delete(worker)
              @waiting << worker
            end
            worker.expires_at = Time.now + 0.001 * @config.heartbeat_expiry
          else
            logger.debug "Worker #{identity} send HEARTBEAT before READY"
            worker.delete(true)
          end
        when DISCONNECT
          worker.delete(false)
      end
    end

    def message_client(sender, message)
      service_name = message.shift
      logger.debug "Client #{sender.unpack('H*').first} send MESSAGE to service #{service_name}"

      case service_name
        when 'mmi.service'
          message_service(sender, message)
        else
          service = Service.require(self, service_name)

          message.unshift nil
          message.unshift sender

          service.requests << message
          service.dispatch
          logger.debug "Queued messages for service [#{service.name}]: #{service.requests.count}"
      end
    end

    def message_service(sender, message)
      command = message.shift

      result = case command
        when 'list-services'
          services.values
        else
          { errors: 'unknown command' }
      end

      message.unshift(result.to_json)
      message.unshift(nil)
      message.unshift(CLIENT)
      message.unshift(nil)
      message.unshift(sender)

      @socket.send_strings(message)
    end

    def purge
      waiting.each do |worker|
        if Time.now > worker.expires_at
          logger.debug "Connection with worker #{worker.identity} lost"
          worker.delete(false)
        end
      end
    end
  end
end
