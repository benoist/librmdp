require 'ffi-rzmq'
require 'majordomo/version'

module Majordomo
  CLIENT = 'MDPC01'
  WORKER = 'MDPW01'

  READY              = "\x01"
  REQUEST            = "\x02"
  REPLY              = "\x03"
  HEARTBEAT          = "\x04"
  DISCONNECT         = "\x05"
  HEARTBEAT_LIVENESS = 3    #  3-5 is reasonable
  HEARTBEAT_INTERVAL = 1000 #  msecs
  HEARTBEAT_EXPIRY   = HEARTBEAT_INTERVAL * HEARTBEAT_LIVENESS
end

require 'majordomo/broker'
require 'majordomo/worker'
require 'majordomo/client'
