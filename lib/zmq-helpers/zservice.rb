# Ruby license. Copyright (c) 2003 Gary Foster <gary.foster@gmail.com>
require 'ffi-rzmq'
require 'json'
require 'socket'
require 'time'

# include Syslog::Constants

# TODO: remove all begin/rescue and let exceptions happen.
# Exceptions were originally logged to preserve thread and
# continue, so they may have to be logged somehow. But we
# can pull in the logging gem to do this and not make it a
# feature of Zservice.

module Zmq
  module Helpers
    class Zservice
      attr_accessor :recv_mode, :recv_bus, :recv_sockets
      attr_accessor :send_mode, :send_bus, :send_socket
      attr_accessor :interval

      attr_reader :recv_type, :send_type

      def topics=(val)
        if val.is_a?(String)
          val = [val]
        end
        @topics = val
      end

      def recv_type=(t)
        @recv_type = t.upcase.to_sym
      end

      def send_type=(t)
        @send_type = t.upcase.to_sym
      end

      def initialize()
        @start_hooks   = []
        @stop_hooks    = []
        @action_hooks  = []
        @timer_hooks   = []

        @poll_thread  = nil
        @timer_threads = []

        @interval     = nil
        @send_socket  = nil

        @recv_sockets = []

        @topics   = [""]

        @recv_bus = ["tcp://127.0.0.1:5556"]
        @send_bus = nil

        @recv_mode = :connect
        @send_mode = :bind

        @recv_type = :SUB
        @send_type = :PUB

        @context = ZMQ::Context.new(1)

      end

      def register(code)
        # register a method to be invoked when an arbitrary key in the message
        # is equal to an arbitrary value
        @action_hooks << method(code)
      end

      def register_before_start(code)
        @start_hooks << method(code)
      end

      def register_before_stop(code)
        @stop_hooks << method(code)
      end

      def register_timer(interval, code)
        @timer_hooks << [interval, method(code)]
      end

      def start(*args)
        @start_hooks.each(&:call)

        create_listeners
        create_publisher if @send_bus

        # spin up our timer threads if we need to

        @timer_hooks.each do |action|
          @timer_threads << Thread.new {
            Timer.every(action[0]) do
              action[1].call
            end
          }
        end

        # make a poller thread that does nothing but service the sockets.
        # When an incoming message hits us, simply spin it off into another
        # short-lived service thread

        @poll_thread = Thread.new do
          poller = ZMQ::Poller.new
          @recv_sockets.each { |s| poller.register(s, ZMQ::POLLIN) }

          loop do
            poller.poll(:blocking)

            poller.readables.each do |s|
              s.recv_string(msg='')

              if msg.strip.empty?
                next
              end

              # we got a message, so do the minimum we need in order to present it
              Thread.new do
                dispatch(msg)
              end # Thread
            end # each
          end # loop
        end # outer dispatch thread

        if args.include?(:blocking)
          @poll_thread.join
        end
      end

      def stop
        if @poll_thread && @poll_thread.alive?
          # we have been started, so let's make sure we run our shutdown hooks first
          @stop_hooks.each(&:call)

          @timer_threads.each do |t|
            Thread.kill(t)
          end

          Thread.kill(@poll_thread)
        end
      end

      ### useful helpers that are designed to be used from within your def methods

      protected

      def kv_parse(text, field_split=",", value_split="=")
        # this will take a delimited string of k/v pairs such as this:
        #  "a=1,b=2,c=3"
        # and turn it into a hash automagically like this:
        # {
        #   "a" => 1,
        #   "b" => 2,
        #   "3" => 3
        # }
        kv_keys = Hash.new
        scan_re = Regexp.new("((?:\\\\ |[^"+field_split+value_split+"])+)["+value_split+"](?:\"([^\"]+)\"|'([^']+)'|((?:\\\\ |[^"+field_split+"])+))")
        text.scan(scan_re) do |key, v1, v2, v3|
          value = v1 || v2 || v3
          kv_keys[key] = value
        end
        return kv_keys
      end

      private

      def dispatch(msg)
        if not msg.include?("@cee:")
          # ok, the message doesn't include a @cee cookie so we pass it through untouched
          # to our handlers and let them deal with it
          @action_hooks.each do |action|
            resp = action.call(msg)
            publish_response(resp) if resp
          end
          return
        end

        # We have a cee cookie, so now let's make sure it's legally parseable

        # msg should look like "topic: @cee:{json}"
        # so let's massage that json out of it

        data = msg.split("@cee:", 2)[1].strip

        # we now have it all parsed out, pass just the json (converted to a hash) to the method
        payload = JSON.parse(data)
         
        @action_hooks.each do |action|
          resp = action.call(payload)
          publish_response(resp) if resp
        end
      end

      def publish_response(msg)
        if not @send_socket.nil?
          # send it out the socket here
          # ffi-rzmq doesn't raise exceptions, it uses return values so check to make sure it went out ok
          rc = @send_socket.send_string(msg)
        end
      end

      def create_listeners
        @recv_bus.each do |s|
          sock = @context.socket(ZMQ.const_get(@recv_type))

          if sock.send(@recv_mode, s) != 0
            raise "request to #{@recv_mode} on #{s} failed"
          end

          if @recv_type == :SUB
            @topics.each do |t|
              sock.setsockopt(ZMQ::SUBSCRIBE, "#{t}")
            end
          end

          @recv_sockets << sock
        end
      end

      def create_publisher
        @send_socket = @context.socket(ZMQ.const_get(@send_type))

          # the connect/bind methods helpfully do not raise errors and instead
          # rely on response values

        if @send_socket.send(@send_mode, @send_bus) != 0
          raise "request to #{@send_mode} on #{@send_bus} failed"
        end
      end
    end
  end
end
