require File.expand_path("../spec_helper", __FILE__)

describe RedRock do
  after do
    RedRock.stop
  end

  context "server" do
    it "listens on port 4242 by default" do
      stub_request :any, "localhost:4242"
      curl = Curl::Easy.http_get "http://localhost:4242"
      curl.response_code.should == 200
    end

    it "allows the port to be overridden" do
      RedRock.start 4567
      stub_request :any, "localhost:4567"
      curl = Curl::Easy.http_get "http://localhost:4567"
      curl.response_code.should == 200
    end

    it "silently ignores attempts to stop non-running server" do
      lambda {RedRock.stop}.should_not raise_error
    end

    it "only runs one server at a time" do
      RedRock.start 4567
      lambda {RedRock.start 4568}.should raise_error(RuntimeError, "RedRock is already running")
    end
  end

  context "on receipt of an unexpected request" do
    let(:curl) { Curl::Easy.http_get "http://localhost:4567" }

    it "returns a 500 error" do
      curl.response_code.should == 500
    end

    it "returns a useful message in the body" do
      curl.body_str.should =~ /Real HTTP connections are disabled/
    end
  end

  context "stubbing with URI only and default response" do
    before do
      stub_request :any, "localhost:4242/foo"
    end

    it "accepts matching requests" do
      curl = Curl::Easy.http_get "http://localhost:4242/foo"
      curl.response_code.should == 200
    end

    it "rejects non-matching requests" do
      curl = Curl::Easy.http_get "http://localhost:4242/bar"
      curl.response_code.should == 500
    end
  end

  context "stubbing with method, URI, body and headers" do
    before do
      stub_request(:any, "localhost:4242/foo").with(:body => "onion", :headers => { "bacon-preference" => "chunky" })
    end

    it "accepts matching requests" do
      curl = Curl::Easy.http_post "http://localhost:4242/foo", "onion" do |c|
        c.headers["bacon-preference"] = "chunky"
      end
      curl.response_code.should == 200
    end

    it "rejects requests with the wrong URI" do
      curl = Curl::Easy.http_post "http://localhost:4242/bar", "onion" do |c|
        c.headers["bacon-preference"] = "chunky"
      end
      curl.response_code.should == 500
    end

    it "rejects requests with the wrong body" do
      curl = Curl::Easy.http_post "http://localhost:4242/foo", "cabbage" do |c|
        c.headers["bacon-preference"] = "chunky"
      end
      curl.response_code.should == 500
    end

    it "rejects requests with the wrong headers" do
      curl = Curl::Easy.http_post "http://localhost:4242/foo", "onion" do |c|
        c.headers["bacon-preference"] = "streaky"
      end
      curl.response_code.should == 500
    end
  end

  context "matching request body and headers against regular expressions" do
    before do
      stub_request(:any, "localhost:4242/foo").with(:body => /nion/, :headers => { "bacon-preference" => /c.*y/ })
    end

    it "accepts matching requests" do
      curl = Curl::Easy.http_post "http://localhost:4242/foo", "onion" do |c|
        c.headers["bacon-preference"] = "chunky"
      end
      curl.response_code.should == 200
    end

    it "rejects requests with the wrong body" do
      curl = Curl::Easy.http_post "http://localhost:4242/foo", "neon" do |c|
        c.headers["bacon-preference"] = "crispy"
      end
      curl.response_code.should == 500
    end

    it "rejects requests with the wrong headers" do
      curl = Curl::Easy.http_post "http://localhost:4242/foo", "bunion" do |c|
        c.headers["bacon-preference"] = "streaky"
      end
      curl.response_code.should == 500
    end
  end

  context "matching request body against a hash" do
    before do
      stub_http_request(:post, "localhost:4242").with(:body => {:data => {:a => '1', :b => 'five'}})
    end

    it "matches URL-encoded data" do
      curl = Curl::Easy.http_post "http://localhost:4242/", "data[a]=1&data[b]=five" do |c|
        c.headers["Content-Type"] = "application/x-www-form-urlencoded"
      end
      curl.response_code.should == 200
    end

    it "matches JSON data" do
      curl = Curl::Easy.http_post "http://localhost:4242/", %({"data":{"a":"1","b":"five"}}) do |c|
        c.headers["Content-Type"] = "application/json"
      end
      curl.response_code.should == 200
    end

    it "matches XML data" do
      curl = Curl::Easy.http_post "http://localhost:4242/", %(<data a="1" b="five" />) do |c|
        c.headers["Content-Type"] = "application/xml"
      end
      curl.response_code.should == 200
    end
  end

  it "supports matching custom request headers"

  it "supports matching multiple headers with the same name"

  it "supports matching requests against a block"

  it "supports basic auth"

  it "supports matching URIs against regular expressions"

  it "supports matching query params using a hash"

  it "supports returning a custom response"

  it "supports returning a custom response"

  it "supports specification of a response body as an IO object"

  it "supports returning a custom status message"

  it "supports replaying raw responses recorded with curl -is"

  it "supports dynamically evaluating responses from a block"

  it "supports dynamically evaluating responses from a lambda"

  it "supports responses with dynamically evaluated parts"

  it "supports setting multiple responses individually"

  it "supports setting multiple responses using chained methods"

  it "supports returning a response a given number of times"

  it "handles test/unit-style assertions"

  it "handles rspec-style assertions"

  it "supports clearing stubs and history"
end
