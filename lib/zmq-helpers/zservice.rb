# Ruby license. Copyright (c) 2003 Gary Foster <gary.foster@gmail.com>
require 'ffi-rzmq'
require 'json'
# require 'logging'
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
      attr_accessor :recv_bus,  :send_bus, :interval

      attr_reader :recv_type, :send_type

      def topics=(val)
        if val.is_a?(String)
          val = [val]
        end
        @topics = val
      end

      # def log_level=(level)
      #   @log.level = level
      # end

      def recv_type=(t)
        @recv_type = t.upcase.to_sym
      end

      def send_type=(t)
        @send_type = t.upcase_to_sym
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

        # @log = setup_logging
        # self.log_level = :debug
      end

      # do we still need this method?
      # def Zservice.finalize(id)
      #   @log.close if @log
      # end

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
        begin
          @timer_hooks << [interval, method(code)]
        rescue => e
          puts "Unable to register timer hook for #{interval} secs, exception #{e.message}"
          # @log.error("Unable to register timer hook for #{interval} secs, exception #{e.message}")
        end
      end

      def start(*args)
        begin
          @start_hooks.each(&:call)
        rescue => e
          puts "Exception raised in start hook, unable to start: #{e.message}"
          # @log.error("Exception raised in start hook, unable to start: #{e.message}")
          raise
        end

        create_listeners
        create_publisher if @send_bus

        # spin up our timer threads if we need to

        @timer_hooks.each do |action|
          @timer_threads << Thread.new {
            Timer.every(action[0]) do
              begin
                action[1].call
              rescue => e
                puts "Exception raised in timer thread: #{e.message}"
                # @log.error("Exception raised in timer thread: #{e.message}")
              end
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
                puts "ignoring blank message"
                # @log.debug("ignoring blank message")
                next
              end

              # we got a message, so do the minimum we need in order to present it
              Thread.new do
                puts "spawning new task thread for message: #{msg}"
                # @log.debug("spawning new task thread for message: #{msg}")
                dispatch(msg)
              end # Thread
            end # each
          end # loop
        end # outer dispatch thread

        if args.include?(:blocking)
          puts "Blocking start requested, joining main thread"
          # @log.debug("Blocking start requested, joining main thread")
          @poll_thread.join
        end
      end

      def stop
        if @poll_thread && @poll_thread.alive?
          # we have been started, so let's make sure we run our shutdown hooks first
          begin
            @stop_hooks.each(&:call)
          rescue => e
            puts "stop hook threw exception #{e.message}, skipping it"
            # @log.error("stop hook threw exception #{e.message}, skipping it")
          end

          @timer_threads.each do |t|
            puts "Killing timer thread"
            # @log.info("Killing timer thread")
            Thread.kill(t)
          end

          puts "Killing main poller thread"
          # @log.info("Killing main poller thread")
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

      # don't need this method
      # def setup_logging
      #   unless defined?(@@log)
      #     # set up our logger
      #     my_name = File.basename($0.chomp(".rb"))
      #     my_host = Socket.gethostname

      #     pattern_hash = {
      #       'host'  => my_host,
      #       'pid'   => '%p',
      #       'sev'   => '%l',
      #       'pname' => my_name,
      #       'time'  => '%d',
      #       'msg'   => '%m',
      #     }

      #     pattern = "@cee:" + pattern_hash.to_json.gsub('"', '\"')

      #     sla = Logging.layouts.pattern(:pattern => pattern)
      #     sla.date_method = 'utc.iso8601'

      #     Logging.appenders.syslog(my_name, :layout => sla)
      #     @@log = Logging.logger['syslog']

      #     @@log.add_appenders(my_name)
      #   end
      #   return @@log
      # end

      def timer_tick
        @timer_hooks.each do |action|
          begin
            action.call
          rescue => e
            puts "Exception #{e.message} raised in timer hook, skipping"
            # @log.error("Exception #{e.message} raised in timer hook, skipping")
          end
        end
      end

      def dispatch(msg)
        if not msg.include?("@cee:")
          # ok, the message doesn't include a @cee cookie so we pass it through untouched
          # to our handlers and let them deal with it
          @action_hooks.each do |action|
            begin
              resp = action.call(msg)
            rescue => e
              puts "Handler threw exception #{e.message}, skipping it"
              # @log.error("Handler threw exception #{e.message}, skipping it")
            end
            publish_response(resp) if resp
          end
          return
        end

        # We have a cee cookie, so now let's make sure it's legally parseable

        # msg should look like "topic: @cee:{json}"
        # so let's massage that json out of it

        data = msg.split("@cee:")[1].strip

        begin
          payload = JSON.parse(data)
        rescue JSON::ParserError => e
          puts "Unable to parse mangled json #{data} with exception #{e.message}, skipping"
          # @log.error("Unable to parse mangled json #{data} with exception #{e.message}, skipping")
          return
        end

        # we now have it all parsed out, pass just the json (converted to a hash) to the method

        @action_hooks.each do |action|
          begin
            resp = action.call(payload)
          rescue => e
            puts "Handler threw exception #{e.message}, skipping it"
            # @log.error("Handler threw exception #{e.message}, skipping it")
          end
          publish_response(resp) if resp
        end
      end

      def publish_response(msg)
        if @send_socket.nil?
          puts "action returned response #{msg} but no publish socket was defined and message was dropped"
          # @log.info("action returned response #{msg} but no publish socket was defined and message was dropped")
        else
          # send it out the socket here
          # ffi-rzmq doesn't raise exceptions, it uses return values so check to make sure it went out ok
          rc = @send_socket.send_string(msg)
          if rc < 0
            puts "attempt to publish response #{msg} on #{@send_bus} returned error RC #{rc}"
            # @log.error("attempt to publish response #{msg} on #{@send_bus} returned error RC #{rc}")
          elsif rc != msg.length
            puts "attempt to publish response #{msg} on #{@send_bus} sent partial message of #{rc} length"
            # @log.error("attempt to publish response #{msg} on #{@send_bus} sent partial message of #{rc} length")
          end
        end
      end

      def create_listeners
        @recv_bus.each do |s|
          begin
            sock = @context.socket(ZMQ.const_get(@recv_type))

            if sock.send(@recv_mode, s) == 0
              puts "Successful #{@recv_mode} to send socket on #{s}"
              # @log.info("Successful #{@recv_mode} to send socket on #{s}")
            else
              raise "request to #{@recv_mode} on #{s} failed"
            end

          rescue => e
            puts "Unable to create sub socket #{s}: #{e.message}"
            # @log.error("Unable to create sub socket #{s}: #{e.message}")
            raise
          end

          if @recv_type == :SUB
            @topics.each do |t|
              puts "subscribing socket #{s} to topic #{t}"
              # @log.info("subscribing socket #{s} to topic #{t}")
              sock.setsockopt(ZMQ::SUBSCRIBE, "#{t}")
            end
          end

          @recv_sockets << sock
        end
      end

      def create_publisher
        begin
          @send_socket = @context.socket(ZMQ.const_get(@send_type))

          # the connect/bind methods helpfully do not raise errors and instead
          # rely on response values

          if @send_socket.send(@send_mode, @send_bus) == 0
            puts "Successful #{@send_mode} to send socket on #{@send_bus}"
            # @log.info("Successful #{@send_mode} to send socket on #{@send_bus}")
          else
            raise "request to #{@send_mode} on #{@send_bus} failed"
          end
        rescue => e
          puts "Unable to create send socket #{@send_socket}: #{e.message}"
          # @log.error("Unable to create send socket #{@send_socket}: #{e.message}")
          raise
        end
      end
    end
  end
end
