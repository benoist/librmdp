require 'ffi-rzmq'
require 'majordomo/version'
require 'active_support/all'
require 'yaml'
require 'json'

module Majordomo
  CLIENT = 'MDPC01'
  WORKER = 'MDPW01'

  Timeout = Class.new(StandardError)

  READY              = "\x01"
  REQUEST            = "\x02"
  REPLY              = "\x03"
  HEARTBEAT          = "\x04"
  DISCONNECT         = "\x05"
  HEARTBEAT_LIVENESS = 3    #  3-5 is reasonable
  HEARTBEAT_INTERVAL = 30*1000 #  msecs
  HEARTBEAT_EXPIRY   = HEARTBEAT_INTERVAL * HEARTBEAT_LIVENESS
end

require 'majordomo/broker'
require 'majordomo/worker'
require 'majordomo/async_client'
