require 'set'

module Majordomo
  class Broker
    class Service
      attr_accessor :broker, :name, :requests, :waiting, :workers, :blacklist

      def initialize(broker, name)
        @broker   = broker
        @name     = name
        @requests = []
        @waiting  = []
        @workers  = 0
      end

      def self.require(broker, name)
        service = broker.services[name]

        if service == nil
          service               = self.new(broker, name)
          broker.services[name] = service
        end
        service
      end

      def as_json(options = {})
        {
            name:            name,
            workers:         workers,
            requests:        requests.count,
            workers_waiting: waiting.count
        }
      end

      def dispatch
        broker.purge
        return if waiting.empty?

        while requests.any?
          worker  = waiting.shift
          message = requests.shift
          worker.send_message(REQUEST, message)
          waiting << worker
        end
      end
    end
  end
end
