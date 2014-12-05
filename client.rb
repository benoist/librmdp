require 'librmdp'

context = ZMQ::Context.new

requests = 1
threads  = 1

start = Time.now
p 'Sending message'
threads.times.collect do
  Thread.new do
    client = Majordomo::AsyncClient.new(Majordomo::Config.new, context)
    requests.times do |i|
      client.send_message('blaat', 'echo')
      client.send_message('mmi.service', 'list-services')

      begin
        puts JSON.parse(client.receive_message(10).first)
      rescue Majordomo::Timeout
        p "Timeout #{i}"
      end
    end
  end
end.map(&:join)


puts (Time.now - start) / (threads*requests)
