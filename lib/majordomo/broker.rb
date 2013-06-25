require 'majordomo/broker/service'
require 'majordomo/broker/worker'

module Majordomo
  class Broker
    HEARTBEAT_LIVENESS = 3    #  3-5 is reasonable
    HEARTBEAT_INTERVAL = 2500 #  msecs
    HEARTBEAT_EXPIRY   = HEARTBEAT_INTERVAL * HEARTBEAT_LIVENESS

    attr_accessor :workers, :waiting, :services

    def initialize
      @context      = ZMQ::Context.new
      @socket       = @context.socket(ZMQ::ROUTER)
      @poller       = ZMQ::Poller.new
      @services     = {}
      @workers      = {}
      @waiting      = []
      @heartbeat_at = Time.now + 0.001 * HEARTBEAT_INTERVAL

      @socket.bind('tcp://*:5555')
      @poller.register(@socket, ZMQ::POLLIN)
      trap(:INT) { exit }
      at_exit { destroy }
    end

    def mediate
      loop do
        items = @poller.poll(HEARTBEAT_INTERVAL)

        if items > 0
          @socket.recv_strings(message = [])
          sender = message.shift
          message.shift #empty
          header = message.shift

          case header
            when MDPC_CLIENT
              message_client(sender, message)
            when MDPC_WORKER
              message_worker(sender, message)
          end
        end

        if Time.now > @heartbeat_at
          purge
          waiting.each do |worker|
            worker.send_message(MDPW_HEARTBEAT, nil, nil)
          end
          @heartbeat_at = Time.now + 0.001 * HEARTBEAT_INTERVAL
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

    def message_worker(sender, *message)
      command      = message.shift
      identity     = sender.unpack('H*').first
      worker_ready = @workers[identity] != nil

      worker = Worker.require(self, sender)

      case command
        when MDPW_READY
          if worker_ready
            worker.delete(true)
          else
            service        = message.shift
            worker.service = Service.require(service)
            @waiting << worker
            worker.service.waiting << worker
            worker.service.workers += 1
            worker.expires_at      = Time.now + 0.001 * HEARTBEAT_EXPIRY
            worker.service.dispatch
          end
        when MDPW_REPORT
          if worker_ready
            client = message.shift
            message.unshift(worker.service.name)
            message.unshift(MDPC_REPORT)
            message.unshift(MDPC_CLIENT)
            message.unshift(nil)
            message.unshift(client)
          else
            worker.delete(true)
          end
        when MDPW_HEARTBEAT
          if worker_ready
            if @waiting.any?
              @waiting.delete(worker)
              @waiting << worker
            end
            worker.expires_at = Time.now + 0.001 + HEARTBEAT_EXPIRY
          else
            worker.delete(true)
          end
        when MDPW_DISCONNECT
          worker.delete(false)
      end
    end

    def message_client(sender, message)
      service_name = message.shift
      service      = Service.require(service_name)

      message.unshift nil
      message.unshift sender

      service.requests << message
      service.dispatch
    end

    def purge
      waiting.each do |worker|
        if Time.now < worker.expires_at
          next
        end
        worker.delete(false)
      end
    end
  end
end
