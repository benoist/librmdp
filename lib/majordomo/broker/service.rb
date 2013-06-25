module Majordomo
  class Broker
    class Service
      attr_accessor :broker, :name, :requests, :waiting, :workers, :blacklist

      def initialize(broker, name)
        @broker    = broker
        @name      = name
        @requests  = []
        @waiting   = []
        @workers   = 0
        @blacklist = Set.new
      end

      def require(broker, name)
        service = broker.services[name]

        if service == nil
          service               = self.new(broker, name)
          broker.services[name] = service
        end
        service
      end

      def dispatch
        broker.purge
        return if waiting.empty?

        while requests.any?
          worker  = waiting.shift
          message = requests.shift
          worker.send_message(MDPW_REQUEST, nil, message)
          waiting << worker
        end
      end

      def enable_command(command)
        @blacklist.delete(command)
      end

      def disable_command(command)
        @blacklist.add(command)
      end

      def command_enabled?(command)
        @blacklist.include?(command)
      end
    end
  end
end
