# Librmdp

A ruby implementation of the majordomo pattern
http://rfc.zeromq.org/spec:7

At this stage it's in POC stage. Use at own risk.

## Installation

Add this line to your application's Gemfile:

    gem 'librmdp'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install librmdp

## Usage

Start a broker
==============

    broker = Majordomo::Broker.new
    broker.mediate

Build a worker with 'echo' as service name
==========================================

    worker = Majordomo::Worker.new('tcp://0.0.0.0:5555', 'echo')

    loop do
      request = worker.receive_message(reply_to = '')
      # do something with a request
      worker.send_message(request, reply_to)
    end

Build a client
==============
    client = Majordomo::Client.new('tcp://0.0.0.0:5555')
    client.send_message('echo', 'a')

    response = client.receive_message

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
