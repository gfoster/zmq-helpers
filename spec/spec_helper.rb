load 'lib/zmq-helpers.rb'
require 'ffi-rzmq'
require 'minitest/mock'

def test_method
  return "in test"
end

def test_msg(msg)
  return msg
end