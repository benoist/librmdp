require 'librmdp'

config = Majordomo::Config.new
Majordomo::Broker.new(config).mediate
