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

  context "replaying raw responses recorded with curl -is" do
    let(:raw_response) do
      <<-EOF
HTTP/1.1 200 OK
Date: Wed, 18 Aug 2010 13:24:53 GMT
Server: Apache/2.2.14 (Unix) mod_ssl/2.2.14 OpenSSL/0.9.8l DAV/2 Phusion_Passenger/2.2.11
Last-Modified: Mon, 29 Jun 2009 12:57:40 GMT
ETag: "13b358c-117-46d7c3c301900"
Accept-Ranges: bytes
Content-Length: 13
Content-Type: text/p[ain

Chunky bacon!
      EOF
    end

    shared_examples_for "a raw response" do
      it "returns the response" do
        curl = Curl::Easy.http_get "http://localhost:4242"
        curl.body_str.should == "Chunky bacon!"
      end
    end

    context "as a file" do
      before do
        File.open "response", "w" do |f|
          f.puts raw_response
        end
        stub_request(:any, "localhost:4242").to_return File.new("response")
      end

      after do
        FileUtils.rm_rf "response"
      end

      it_should_behave_like "a raw response"
    end

    context "as a string" do
      before do
        stub_request(:any, "localhost:4242").to_return raw_response
      end

      it_should_behave_like "a raw response"
    end
  end

  context "dynamically evaluating responses" do
    shared_examples_for "a dynamic response" do
      it "returns the correct response" do
        curl = Curl::Easy.http_post "http://localhost:4242", "!nocab yknuhC"
        curl.body_str.should == "Chunky bacon!"
      end
    end

    context "from a block" do
      before do
        stub_request(:any, "localhost:4242").to_return { |request| {:body => request.body.reverse} }
      end

      it_should_behave_like "a dynamic response"
    end

    context "from a lambda" do
      before do
        stub_request(:any, "localhost:4242").to_return(lambda { |request| {:body => request.body.reverse} })
      end

      it_should_behave_like "a dynamic response"
    end

    context "by part" do
      before do
        stub_request(:any, "localhost:4242").to_return(:body => lambda { |request| request.body.reverse })
      end

      it_should_behave_like "a dynamic response"
    end
  end

  context "setting multiple responses" do
    shared_examples_for "multiple responses" do
      it "returns the correct values" do
        curl = Curl::Easy.new "http://localhost:4242"
        (1..3).map do
          curl.http_get
          curl.body_str
        end.should == %w(chunky chunky bacon)
      end
    end

    context "individually" do
      before do
        stub_request(:get, "localhost:4242").to_return({:body => "chunky"},
                                                       {:body => "chunky"},
                                                       {:body => "bacon"})
      end

      it_should_behave_like "multiple responses"
    end

    context "using method chaining" do
      before do
        stub_request(:get, "localhost:4242").to_return({:body => "chunky"}).then.
          to_return({:body => "chunky"}).then.to_return({:body => "bacon"})
      end

      it_should_behave_like "multiple responses"
    end

    context "specifying the number of times to return a given response" do
      before do
        stub_request(:get, "localhost:4242").to_return({:body => "chunky"}).times(2).then.
          to_return({:body => "bacon"})
      end

      it_should_behave_like "multiple responses"
    end
  end

  context "assertions" do
    before do
      stub_request :any, "localhost:4242/foo"
      Curl::Easy.http_get "http://localhost:4242/foo"
    end

    context "in the test/unit style" do
      it "can assert requests made" do
        assert_requested :get, "http://localhost:4242/foo"
      end

      it "can assert requests not made" do
        assert_not_requested :get, "http://localhost:4242/bar"
      end
    end

    context "in the rspec style" do
      it "can assert requests made" do
        RedRock.should have_requested :get, "http://localhost:4242/foo"
      end

      it "can assert requests not made" do
        RedRock.should_not have_requested :get, "http://localhost:4242/bar"
      end
    end

    context "in the alternative rspec style" do
      it "can assert requests made" do
        request(:get, "http://localhost:4242/foo").should have_been_made
      end

      it "can assert requests not made" do
        request(:get, "http://localhost:4242/bar").should_not have_been_made
      end
    end
  end

  context "resetting" do
    before do
      stub_request :any, "localhost:4242"
      Curl::Easy.http_get "http://localhost:4242"
      reset_webmock
    end

    it "clears stubs" do
      curl = Curl::Easy.http_get "http://localhost:4242"
      curl.response_code.should == 500
    end

    it "clears history" do
      request(:get, "http://localhost:4242").should_not have_been_made
    end
  end
end
