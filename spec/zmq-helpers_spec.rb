require 'spec_helper'

describe Zmq::Helpers::Zservice, "#new" do
  it "returns a new object with default initialization values" do
    # new instance
    service = Zmq::Helpers::Zservice.new
    # all instance vars with accessors
    service.recv_mode.should eq(:connect)
    service.recv_bus.should eq(["tcp://127.0.0.1:5556"])
    service.recv_sockets.should eq([])
    service.send_mode.should eq(:bind)
    service.send_bus.should eq(nil)
    service.send_socket.should eq(nil)
    service.interval.should eq(nil)
    service.recv_type.should eq(:SUB)
    service.send_type.should eq(:PUB)

    # instance vars without accessors
    service.instance_variable_get(:@start_hooks).should eq([])
    service.instance_variable_get(:@stop_hooks).should eq([])
    service.instance_variable_get(:@action_hooks).should eq([])
    service.instance_variable_get(:@timer_hooks).should eq([])
    service.instance_variable_get(:@poll_thread).should eq(nil)
    service.instance_variable_get(:@timer_threads).should eq([])
    service.instance_variable_get(:@interval).should eq(nil)
    # service.instance_variable_get(:@context).should be_an_instance_of(ZMQ::Context.new(1))
    # is this the correct way to test for object creation?
    # service.instance_variable_get(:@context).should eq(ZMQ::Context.new(1))
    # purposefully not testing logging setup now
  end
end

describe Zmq::Helpers::Zservice, "#topics" do
  it "allows you to set topic subscription" do
    service = Zmq::Helpers::Zservice.new
    service.topics = ['rg_event']
    service.instance_variable_get(:@topics).should eq(['rg_event'])
  end
end

describe Zmq::Helpers::Zservice, "#recv_bus" do
  it "allows you to override the tcp bus" do
    service = Zmq::Helpers::Zservice.new
    service.recv_bus = ["tcp://localhost:1234"]
    service.recv_bus.should eq(["tcp://localhost:1234"])
  end
end

describe Zmq::Helpers::Zservice, "#register_before_start" do
  it "allows you to add a method to the start hooks array" do
    service = Zmq::Helpers::Zservice.new
    def setup
      setup_var = "message in setup var"
    end

    s = method(:setup)
    # for some reason, rspec thinks :setup is part of zservice
    # so we get an undefined method error (NameError)
    service.register_before_start(:setup)
    # test that the method in zservice is the same as s
    start_hooks = service.instance_variable_get(:@start_hooks)
    start_hooks[1].should eq(s)
  end
end

describe Zmq::Helpers::Zservice, "#" do
end
