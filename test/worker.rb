$LOAD_PATH << File.join(File.expand_path(__FILE__), '../../lib')
require 'librmdp'

worker = Majordomo::Worker.new('tcp://0.0.0.0:5555', 'echo')

loop do
  request = worker.receive_message(reply_to = '')
  worker.send_message(request, reply_to)
end
