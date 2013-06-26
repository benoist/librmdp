$LOAD_PATH << File.join(File.expand_path(__FILE__), '../lib')
require 'librmdp'

broker = Majordomo::Broker.new
broker.mediate
