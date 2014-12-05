module Majordomo
  class Config
    attr_accessor :log_level, :heartbeat_interval, :heartbeat_liveness, :broker_endpoint, :logger

    def initialize
      defaults = {
          log_level:          Logger::DEBUG,
          logger:             ActiveSupport::Logger.new(STDOUT),
          heartbeat_interval: HEARTBEAT_INTERVAL,
          heartbeat_liveness: HEARTBEAT_LIVENESS,
          broker_endpoint:    'tcp://127.0.0.1:5555'
      }
      configure(defaults)

      logger.level = log_level
    end

    def configure(attributes = {}, &block)
      if attributes.present?
        attributes.each do |key, value|
          public_send("#{key}=", value)
        end
      elsif block_given?
        block.call(self)
      else
        raise ArgumentError.new('Configure requires a Hash or a Block')
      end
    end

    def heartbeat_expiry
      heartbeat_interval * heartbeat_liveness
    end
  end
end
