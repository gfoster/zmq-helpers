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

# how do I test for def method=(arg) methods?
describe Zmq::Helpers::Zservice, "#recv_type" do
  it "sets the instance variable @recv_type to uppercase string" do
    pending "fixing the test for setting recv_type"
    service = Zmq::Helpers::Zservice.new
    service.recv_type("string")
    service.instance_variable_get(@recv_type).should eq(:STRING)
  end
end

describe Zmq::Helpers::Zservice, "#recv_bus" do
  it "allows you to override the tcp bus" do
    service = Zmq::Helpers::Zservice.new
    service.recv_bus = ["tcp://localhost:1234"]
    service.recv_bus.should eq(["tcp://localhost:1234"])
  end
end

# this test will fail similar to the test below
describe Zmq::Helpers::Zservice, "#register" do
  it "adds the specified method to the action hooks array" do
    service = Zmq::Helpers::Zservice.new
  end
end

describe Zmq::Helpers::Zservice, "#register_before_start" do
  it "allows you to add a method to the start hooks array" do
    pending "properly passing arg to register_before_start function"
    service = Zmq::Helpers::Zservice.new
    # def setup
    #   setup_var = "message in setup var"
    # end

    # s = method(:setup)
    # for some reason, rspec thinks :setup is part of zservice
    # so we get an undefined method error (NameError)
    service.register_before_start(:setup)
    # test that the method in zservice is the same as s
    # start_hooks = service.instance_variable_get(:@start_hooks)
    # start_hooks[1].should eq(s)
  end
end

describe Zmq::Helpers::Zservice, "#register_before_stop" do
  it "adds the specified method to the stop hooks array" do
    service = Zmq::Helpers::Zservice.new
  end
end

describe Zmq::Helpers::Zservice, "#register_timer" do
  it "adds a method to the timer hooks aray and specifies a time interval" do
    pending "checking correct instance variable"
    service = Zmq::Helpers::Zservice.new
    service.register_timer(60, :test_method)
    service.instance_variable_get(:timer_hooks).should eq([60, method(:test_method)])
  end
end

describe Zmq::Helpers::Zservice, "#start" do
  it "starts a thread and calls start hooks" do
    pending "checking the thread and start hooks"
  end
end

describe Zmq::Helpers::Zservice, "#stop" do
  it "kills the thread and calls stop hooks" do
    pending "checking the thread and stop hooks"
  end
end

describe Zmq::Helpers::Zservice, "#kv_parse" do
  it "returns keys and values from a string" do
    pending "checking kv parse method"
  end
end

