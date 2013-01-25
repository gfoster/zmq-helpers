#!/usr/bin/env ruby

# aggregate a rate count of all events on the event bus and report
# a count every minute

require 'zmq-helpers'

# This method gets called before startup and sets up all our relevant ivars
def setup
  @lock = Mutex.new

  # Oh noes, a Mutex?  Whaaa?  Well, we plan on having a counter that is updated every
  # time an incoming message is processed.  Since the actual processing happens in
  # its own thread, we need to make sure we don't end up clobbering ourselves.

  # Technically, in MRI we don't need a mutex to ensure thread safe writes to our
  # counter (thanks to the GIL) and if we want to rely on the VM to enforce things we
  # could get rid of this mutex.  However, if we were to run this in another engine
  # (such as jruby) which doesn't use a GIL, we could conceivably run into concurrency
  # issues so it's just generally good practice to synchronize things.  Be kind to the
  # next person and don't introduce weird bugs that depend on the VM implementation to
  # enforce proper behavior

  @counter = 0
end

# this method will get triggered for every event
def count(msg)
  @lock.synchronize { @counter += 1 }
end

# This method will be triggered by a timer
def display_count
  event_rate = 0

  @lock.synchronize do
    event_rate = @counter / 60.0
    @counter = 0
  end

  puts "Processed #{event_rate} events per second for the last 60 seconds"
end

######

if __FILE__ == $PROGRAM_NAME
  service = Zmq::Helpers::Zservice.new()

  service.log_level = :warn # cut down the log spam (default is :debug)
  service.topics    = ['']  # we want to see ALL messages

  # defaults to attaching a SUB socket to a PUB bus (but this behavior can be changed)
  service.recv_bus  = ["tcp://localhost:5555"]

  service.register_before_start(:setup)
  service.register_timer(60, :display_count)
  service.register(:count)

  service.start(:blocking)
end
