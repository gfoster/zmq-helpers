load 'lib/zmq-helpers.rb'
require 'ffi-rzmq'
require 'minitest/mock'
require 'debugger'

def test_method
  return "in test"
end

def test_msg(msg)
  return msg
end

def test_exception
  raise "exception test"
end