$LOAD_PATH << File.join(File.expand_path(__FILE__), '../../lib')
require 'librmdp'
require 'benchmark'

client = Majordomo::Client.new('tcp://0.0.0.0:5555')

results = Benchmark.measure do
  requests = 10_000
  start = Time.now
  requests.times do
    client.send_message('echo', 'a')
  end
  requests.times do
    client.receive_message
  end
  puts 1.0 / (Time.now - start) * requests
end

puts results
