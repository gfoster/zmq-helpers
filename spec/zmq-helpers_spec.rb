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
  it "starts a thread and calls start hooks" do
    pending "checking the thread and start hooks"
    # Test for the following:
    # start hook methods called
    # create_listeners called (test this function)
    # create_publisher called (test this function)
    # timer_hooks: each spins up thread, function called every timer interval
    #
  end
end

describe Zmq::Helpers::Zservice, "#stop" do
  it "kills the thread and calls stop hooks if thread exists and is alive" do
    pending "checking the thread and stop hooks"
  end

  it "will not kill thread if one does not exist" do
  end
end

# these are all private methods
describe Zmq::Helpers::Zservice, "#kv_parse" do
  it "returns keys and values from a string" do
    # pending "Stub method for proper testing"
    message = "a=1,b=2,c=3"
    service = Zmq::Helpers::Zservice.new
    parsed = service.send(:kv_parse, message)
    parsed.should eq({"a" => "1", "b" => "2", "c" => "3"})
  end
end

# this method may need to be changed or omitted - it doesn't account
# for nested array
describe Zmq::Helpers::Zservice, "#timer_tick" do
  it "runs the timer hooks" do
    pending "this example fails, fix in code"
    service = Zmq::Helpers::Zservice.new
    service.register_timer(60, :test_method)
    response = service.instance_variable_get(:@timer_hooks)
    service.send(:timer_tick).should eq(response[0][1].call)
    # pending "checking timer hooks"
  end
end
cee_message = '@cee: {"host":"mcoyle1.rgops.com","pname":"irb","time":"2013-07-09 18:14:46 UTC","sev":6,"msg":"test"}'
reg_message = '"GET /events?rg_type=2.4.5:info&rg_player_type=standard&rg_publisher=gossipcenter&rg_publisher_id=1228&rg_domain_category_id=&rg_domain_id=9439103338f821227104719fde61bf12&rg_page_host_url=http%3A%2F%2Fgossipcenter.com%2Fjennifer-lopez%2Fvideo%2Fjlo-under-fire-human-rights-group&rg_ad_domain_id=undefined&rg_player_uuid=e8a48200-53b1-42ee-9fd0-4bd701f060c1&rg_video_catalog_id=621&rg_video_index_id=34&rg_guid=76fc5295-a1f8-4f29-8e29-d8b72f08a958&rg_session=a1a9a9d4a7cf4818d00e8563862f0d86&rg_counter=0&rg_event=jwplayerPlaylistItem&rg_iframe=false&rg_referrer=http%3A%2F%2Fgossipcenter.com%2Felton-john%2Felton-john-postpones-summer-tour-due-appendicitis-885671&rg_settings=Mute:%20false%20Volume:%2020%20Autostart:%20false&rg_documenthidden=false&rg_lable=http://videos.realgravity.com/1073/content/281596/1187960-76fc5295-a1f8-4f29-8e29-d8b72f08a958.mp4&rg_category=Playlist%20Pick HTTP/1.1" 200 0 "-" "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.116 Safari/537.36"'

# dispatch needs to be tested for handling a cee and non cee message
describe Zmq::Helpers::Zservice, "#dispatch" do
  it "handles message without cee cookie" do
    # pending "check message for cee cookie"
    service = Zmq::Helpers::Zservice.new
    service.register(:test_method)
    service.send(:dispatch, cee_message)
    # payload vs data - how to test?
  end

  it "handles message with cee cookie and parses it" do
    service = Zmq::Helpers::Zservice.new
    service.register(:test_method)
    service.send(:dispatch, reg_message)
    # pending "check message with cee cookie"
  end

end

describe Zmq::Helpers::Zservice, "#publish_response" do
  it "publishes the messages to the socket" do
    pending "publish message to bus"
  end
end

describe Zmq::Helpers::Zservice, "#create_listenters" do
  it "creates socket listeners" do
  end
end

describe Zmq::Helpers::Zservice, "#create_publisher" do
  it "creates the socket to publish messages" do
  end
end
