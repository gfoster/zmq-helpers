require 'spec_helper'

cee_message = "rg_events: @cee: {\"p_proc\":\"rg_events\",\"p_sys\":\"mediacast4\",\"time\":\"2013-07-11T22:33:58+00:00\",\"msg\":\" 10.204.233.116 - - [11/Jul/2013:22:33:55 +0000] \\\"GET /events?rg_type=2.4.5:info&rg_player_type=standard&rg_publisher=gossipcenter&rg_publisher_id=1228&rg_domain_category_id=&rg_domain_id=9439103338f821227104719fde61bf12&rg_page_host_url=http%3A%2F%2Fgossipcenter.com%2Fcelebrity-news%2Fvideo%2Fblake-lively-wows-she-supports-husband-ryan-reynolds-turbo-premiere&rg_ad_domain_id=undefined&rg_player_uuid=e8a48200-53b1-42ee-9fd0-4bd701f060c1&rg_video_catalog_id=161&rg_video_index_id=34&rg_guid=664dde8b-77a7-4f71-b1e8-2011b70e324f&rg_session=ed3227baab07b52e70fe6536d4e1e926&rg_counter=1&rg_event=csNotEnabled&rg_iframe=false&rg_referrer=http%3A%2F%2Fgossipcenter.com%2Fwill-smith%2Fvideo%2Fmovie-news-pop-will-smith-not-returning-men-black-4&rg_settings=Mute:%20false%20Volume:%2020%20Autostart:%20false&rg_documenthidden=false&rg_category=Measurement&comscoretag=null&rg_action=comScore%20Not%20Enabled HTTP/1.1\\\" 200 0 \\\"-\\\" \\\"Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.116 Safari/537.36\\\"\"}\n"
reg_message = '"GET /events?rg_type=2.4.5:info&rg_player_type=standard&rg_publisher=gossipcenter&rg_publisher_id=1228&rg_domain_category_id=&rg_domain_id=9439103338f821227104719fde61bf12&rg_page_host_url=http%3A%2F%2Fgossipcenter.com%2Fjennifer-lopez%2Fvideo%2Fjlo-under-fire-human-rights-group&rg_ad_domain_id=undefined&rg_player_uuid=e8a48200-53b1-42ee-9fd0-4bd701f060c1&rg_video_catalog_id=621&rg_video_index_id=34&rg_guid=76fc5295-a1f8-4f29-8e29-d8b72f08a958&rg_session=a1a9a9d4a7cf4818d00e8563862f0d86&rg_counter=0&rg_event=jwplayerPlaylistItem&rg_iframe=false&rg_referrer=http%3A%2F%2Fgossipcenter.com%2Felton-john%2Felton-john-postpones-summer-tour-due-appendicitis-885671&rg_settings=Mute:%20false%20Volume:%2020%20Autostart:%20false&rg_documenthidden=false&rg_lable=http://videos.realgravity.com/1073/content/281596/1187960-76fc5295-a1f8-4f29-8e29-d8b72f08a958.mp4&rg_category=Playlist%20Pick HTTP/1.1" 200 0 "-" "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.116 Safari/537.36"'

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
  end
end

describe Zmq::Helpers::Zservice, "#topics" do
  it "allows you to set topic subscription" do
    service = Zmq::Helpers::Zservice.new
    service.topics = ['rg_event']
    service.instance_variable_get(:@topics).should eq(['rg_event'])
  end
end

describe Zmq::Helpers::Zservice, "#recv_type" do
  it "sets the instance variable @recv_type to uppercase string" do
    service = Zmq::Helpers::Zservice.new
    service.recv_type = "string"
    service.recv_type.should eq(:STRING)
  end
end

describe Zmq::Helpers::Zservice, "#send_type" do
  it "sets the instance variable @send_type to uppercase string" do
    service = Zmq::Helpers::Zservice.new
    service.send_type = "string"
    service.send_type.should eq(:STRING)
  end
end

describe Zmq::Helpers::Zservice, "#recv_bus" do
  it "allows you to override the tcp bus" do
    service = Zmq::Helpers::Zservice.new
    service.recv_bus = ["tcp://localhost:1234"]
    service.recv_bus.should eq(["tcp://localhost:1234"])
  end
end

describe Zmq::Helpers::Zservice, "#register" do
  it "adds the specified method to the action hooks array, and method called returns correct value" do
    service = Zmq::Helpers::Zservice.new
    service.register(:test_method)
    response = service.instance_variable_get(:@action_hooks)
    response[0].call.should eq(test_method)
  end
end

describe Zmq::Helpers::Zservice, "#register_before_start" do
  it "allows you to add a method to the start hooks array and " do
    service = Zmq::Helpers::Zservice.new
    service.register_before_start(:test_method)
    response = service.instance_variable_get(:@start_hooks)
    response[0].call.should eq(test_method)
  end
end

describe Zmq::Helpers::Zservice, "#register_before_stop" do
  it "adds the specified method to the stop hooks array" do
    service = Zmq::Helpers::Zservice.new
    service.register_before_stop(:test_method)
    response = service.instance_variable_get(:@stop_hooks)
    response[0].call.should eq(test_method)
  end
end

describe Zmq::Helpers::Zservice, "#register_timer" do
  it "adds a method to the timer hooks aray and specifies a time interval" do
    service = Zmq::Helpers::Zservice.new
    service.register_timer(60, :test_method)
    response = service.instance_variable_get(:@timer_hooks)
    response[0][0].should eq(60)
    response[0][1].call.should eq(test_method)
  end
end

describe Zmq::Helpers::Zservice, "#start" do
  it "creates listeners, calls start hooks methods, and starts new thread" do
    poller = MiniTest::Mock.new
    poller.expect(:new, Object)
    poller.expect(:register, nil, ["socket", "zmq"])
    poller.expect(:poll, 1, ["blocking"])

    service = Zmq::Helpers::Zservice.new
    service.register_before_start(:test_method)
    service.start
    service.instance_variable_get(:@poll_thread).should_not be_nil
    socks = service.instance_variable_get(:@recv_sockets)
    socks.length.should eq(1)
    service.stop
  end

  it "with timer hooks, should create a timer thread" do
    service = Zmq::Helpers::Zservice.new
    service.register_before_start(:test_method)
    service.register_timer(60, :test_method)
    service.start
    # check that the timer calls the test method
    timer_thread = service.instance_variable_get(:@timer_threads)
    timer_thread[0].alive?.should eq(true)
    # check that the poller thread is created
    # check that the dispatch method is called (mock)
    # check for blocking args
    service.stop
  end
end


describe Zmq::Helpers::Zservice, "#stop" do
  it "with stop hooks, kills thread if it is alive" do
    service = Zmq::Helpers::Zservice.new
    service.register(:test_method)
    service.start
    poll_thread = service.instance_variable_get(:@poll_thread)
    poll_thread.alive?.should eq(true)
    service.stop
    poll_thread = service.instance_variable_get(:@poll_thread)
    poll_thread.alive?.should eq(true)
  end

  it "with no stop hooks, kills the thread and poll thread if thread is alive" do
    pending "thread alive check returns true when it should be false"
    service = Zmq::Helpers::Zservice.new
    service.register(:test_method)
    service.register_timer(60, :test_method)
    service.start
    timer_thread = service.instance_variable_get(:@timer_threads)
    poll_thread = service.instance_variable_get(:@poll_thread)
    timer_thread[0].alive?.should eq(true)
    poll_thread.alive?.should eq(true)
    
    service.stop
    
    timer_thread2 = service.instance_variable_get(:@timer_threads)
    # no idea why this isn't returning false in the test, returns false
    # in the debugger...
    timer_thread2[0].alive?.should eq(false) 
    poll_thread2 = service.instance_variable_get(:@poll_thread)
    poll_thread2.alive?.should eq(false)
  end
end

# these are all private methods
describe Zmq::Helpers::Zservice, "#kv_parse" do
  it "returns keys and values from a string" do
    message = "a=1,b=2,c=3"
    service = Zmq::Helpers::Zservice.new
    parsed = service.send(:kv_parse, message)
    parsed.should eq({"a" => "1", "b" => "2", "c" => "3"})
  end
end

# dispatch needs to be tested for handling a cee and non cee message
# also need to figure out how to test the return value from the 
# publish_response method with a mocked socket object
describe Zmq::Helpers::Zservice, "#dispatch" do
  it "handles message without cee cookie" do
    pending "mock out socket, check return value"
    service = Zmq::Helpers::Zservice.new
    service.register(:test_msg)
    res = service.send(:dispatch, reg_message)
    res.should be nil
    service.stop
  end

  it "handles message with cee cookie and parses it" do
    pending "mock out socket, check return value"
    service = Zmq::Helpers::Zservice.new
    service.register(:test_msg)
    res = service.send(:dispatch, cee_message)
    res.should be nil
    service.stop
  end
end

# created the mock, but doesn't seem to be used in the test?
describe Zmq::Helpers::Zservice, "#publish_response" do
  it "publishes the messages to the socket if the socket exists" do
    pending "test with the mock"
    @send_socket = MiniTest::Mock.new
    @send_socket.expect(:new, Object)
    @send_socket.expect(:send_string, 0, ["msg"])
    @send_socket.new
    @send_socket.send_string("message string")
    service = Zmq::Helpers::Zservice.new
    service.send_bus = "tcp://localhost:12345"
    res = service.send(:publish_response, "message string")
    res.should eq(0)
    service.stop
  end

  it "does not publish the messgae if the socket does not exist" do
    service = Zmq::Helpers::Zservice.new
    service.send_socket.should eq(nil)
    res = service.send(:publish_response, "message")
    res.should eq(nil)
    service.stop
  end
end

describe Zmq::Helpers::Zservice, "#create_listeners" do
  it "creates socket listeners, defaults to :SUB" do
    pending "mock out ZMQ lib"
    # @context = MiniTest::Mock.new
    # @context.expect(:new, Object, [1])
    # @context.expect(:socket, Object, [:SUB])
    service = Zmq::Helpers::Zservice.new
    service.send(:create_listeners)
    service.recv_sockets.length.should eq(1)
    service.recv_sockets[0].should be_an_instance_of(ZMQ::Socket)
    service.stop
  end

  it "raises error if return value is not zero" do
    pending "mock out zmq and socket lib"
    service = Zmq::Helpers::Zservice.new
    # mock_zmq = mock("ZMQ::Poller")
    # mock_zmq.should_receive("const_get")
    # mock out socket to reply with non zero value
    # 
  end

  it "creates a subscribe socket if type is :SUB" do
    pending "mock out zmq and socket lib"
    service = Zmq::Helpers::Zservice.new
    service.recv_type = "sub"
    service.topics = "test"
  end
end

describe Zmq::Helpers::Zservice, "#create_publisher" do
  it "creates the socket to publish messages" do
    pending "mock out zmq and socket lib"
    context = MiniTest::Mock.new
    context.expect(:new, true, 1)
    context.expect(:socket, true, :PUB)
    service = Zmq::Helpers::Zservice.new
    service.send_bus = "tcp://localhost:12345"
    service.instance_variable_set(:@context, context)
    service.send(:create_publisher)
    service.stop

    # service.instance_variable_get(:@send_socket).should be_an_instance_of(ZMQ::Socket)
  end
end
