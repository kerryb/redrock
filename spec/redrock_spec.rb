require File.expand_path("../spec_helper", __FILE__)

# Mostly uses curb to avoid going via net/http, to prove that the stubbing
# isn't happening locally.

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

  context "matching multiple headers with the same name" do
    before do
      stub_http_request(:get, "localhost:4242").with(:headers => {"Accept" => ["image/jpeg", "image/png"]})
    end

    it "matches when both header values are present" do
      # Curb can't do multiple headers with the same name
      req = Net::HTTP::Get.new("/")
      req['Accept'] = ['image/png']
      req.add_field('Accept', 'image/jpeg')
      resp = Net::HTTP.start("localhost:4242") {|http|  http.request(req) }
      resp.should be_an_instance_of Net::HTTPOK
    end

    it "rejects requests with missing values" do
      curl = Curl::Easy.http_get "http://localhost:4242/" do |c|
        c.headers["Accept"] = "image/jpeg"
      end
      curl.response_code.should == 500
    end
  end

  context "matching requests against a block" do
    before do
      stub_request(:post, "localhost:4242").with { |request| request.body == "abc" }
    end

    it "matches when the block returns true" do
      curl = Curl::Easy.http_post "http://localhost:4242", "abc"
      curl.response_code.should == 200
    end

    it "does not match when the block returns false" do
      curl = Curl::Easy.http_post "http://localhost:4242", "def"
      curl.response_code.should == 500
    end
  end

  context "using basic auth" do
    before do
      stub_request(:get, "user:pass@localhost:4242")
    end

    it "matches when the username and password are correct" do
      curl = Curl::Easy.http_get "http://localhost:4242/" do |c|
        c.http_auth_types = :basic
        c.username = "user"
        c.password = "pass"
      end
      curl.response_code.should == 200
    end
  end

  context "matching URIs against regular expressions" do
    before do
      stub_request :any, %r(local.*/foo)
    end

    it "accepts matching requests" do
      curl = Curl::Easy.http_get "http://localhost:4242/wibble/foo"
      curl.response_code.should == 200
    end

    it "rejects non-matching requests" do
      curl = Curl::Easy.http_get "http://localhost:4242/bar"
      curl.response_code.should == 500
    end
  end

  context "matching query params using a hash" do
    before do
      stub_http_request(:get, "localhost:4242").with(:query => {"a" => ["b", "c"]})
    end

    it "accepts matching requests" do
      curl = Curl::Easy.http_get "http://localhost:4242?a[]=b&a[]=c"
      curl.response_code.should == 200
    end

    it "rejects non-matching requests" do
      curl = Curl::Easy.http_get "http://localhost:4242?a[]=d"
      curl.response_code.should == 500
    end
  end

  context "returning a custom response" do
    before do
      stub_request(:any, "localhost:4242").to_return(:body => "abc", :status => 201,
                                                     :headers => { "Location" => "nowhere"})
    end

    let(:curl) { Curl::Easy.http_get "http://localhost:4242" }

    it "returns the specified body" do
      curl.body_str.should == "abc"
    end

    it "returns the specified response code" do
      curl.response_code.should == 201
    end

    it "returns the specified headers" do
      curl.header_str.should =~ /location: nowhere/
    end
  end

  it "supports specification of a response body as an IO object" do
    stub_request(:any, "localhost:4242").to_return(:body => StringIO.new("chunky bacon"), :status => 200)
    curl = Curl::Easy.http_get "http://localhost:4242"
    curl.body_str.should == "chunky bacon"
  end

  context "returning a custom status message" do
    before do
      stub_request(:any, "localhost:4242").to_return(:status => [500, "Pixies are on strike"])
    end

    let(:resp) do
      uri = URI.parse "http://localhost:4242"
      Net::HTTP.start(uri.host, uri.port) {|http|
        http.get "/"
      }
    end

    it "returns the specified response code" do
      resp.code.should == "500"
    end

    it "returns the specified message" do
      resp.message.should == "Pixies are on strike"
    end
  end

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
