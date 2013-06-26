module Majordomo
  class Broker
    class Worker
      attr_accessor :broker, :identity, :address, :service, :expires_at

      def initialize(broker, identity, address)
        @broker   = broker
        @identity = identity
        @address  = address
      end

      def self.require(broker, address)
        identity = address.unpack('H*').first
        worker   = broker.workers[identity]

        if worker == nil
          worker                   = self.new(broker, identity, address)
          broker.workers[identity] = worker
        end

        worker
      end

      def delete(disconnect)
        if disconnect
          send_message(DISCONNECT)
        end

        if service
          service.waiting.delete(self)
          service.workers -= 1
        end
        broker.waiting.delete(self)
        broker.workers.delete(identity)
      end

      def send_message(command, message = [])
        message.unshift(command)
        message.unshift(WORKER)
        message.unshift(nil)
        message.unshift(address)

        broker.socket.send_strings(message)
      end
    end
  end
end
