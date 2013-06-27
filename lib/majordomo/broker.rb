require 'majordomo/broker/service'
require 'majordomo/broker/worker'

module Majordomo
  class Broker

    attr_accessor :workers, :waiting, :services, :socket

    def initialize(bind = 'tcp://*:5555', context = ZMQ::Context.new)
      @context      = context
      @socket       = @context.socket(ZMQ::ROUTER)
      @poller       = ZMQ::Poller.new
      @services     = {}
      @workers      = {}
      @waiting      = []
      @heartbeat_at = Time.now + 0.001 * HEARTBEAT_INTERVAL

      @socket.bind(bind)
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
          @heartbeat_at = Time.now + 0.001 * HEARTBEAT_INTERVAL
          puts "Heartbeat #{waiting.count}"
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
            worker.delete(true)
          else
            service        = message.shift
            worker.service = Service.require(self, service)
            @waiting << worker
            worker.service.waiting << worker
            worker.service.workers += 1
            worker.expires_at      = Time.now + 0.001 * HEARTBEAT_EXPIRY
            worker.service.dispatch
          end
        when REPLY
          if worker_ready
            client = message.shift
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
            worker.expires_at = Time.now + 0.001 * HEARTBEAT_EXPIRY
          else
            worker.delete(true)
          end
        when DISCONNECT
          worker.delete(false)
      end
    end

    def message_client(sender, message)
      service_name = message.shift
      service      = Service.require(self, service_name)

      message.unshift nil
      message.unshift sender

      service.requests << message
      service.dispatch
    end

    def purge
      waiting.each do |worker|
        worker.delete(false) if Time.now > worker.expires_at
      end
    end
  end
end
