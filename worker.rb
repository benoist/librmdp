require 'librmdp'

worker   = Majordomo::Worker.new('tcp://0.0.0.0:5555', 'blaat')
@running = true

while @running do
  request = worker.receive_message(reply_to = '')
  # do something with a request

  # sleep rand(5)

  worker.send_message(request, reply_to)
end
