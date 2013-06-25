require 'ffi-rzmq'
require 'majordomo/version'

module Majordomo
  MDPC_CLIENT = "MDPC0X"

  MDPC_REQUEST = "\x01"
  MDPC_REPORT  = "\x02"
  MDPC_NAK     = "\x03"

  MDPC_COMMANDS =[NULL, 'REQUEST', 'REPORT', 'NAK']

  MDPW_WORKER = 'MDPW0X'

  MDPW_READY      = "\x01"
  MDPW_REQUEST    = "\x02"
  MDPW_REPORT     = "\x03"
  MDPW_HEARTBEAT  = "\x04"
  MDPW_DISCONNECT = "\x05"

  MDPW_COMMANDS [NULL, 'READY', 'REQUEST', 'REPORT', 'HEARTBEAT', 'DISCONNECT']
end

require 'majordomo/broker'
