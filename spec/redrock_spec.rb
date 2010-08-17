require File.expand_path("../spec_helper", __FILE__)

describe RedRock do
  it "listens on port 4242 by default" do
    stub_request :any, "localhost:4242"
    curl = Curl::Easy.http_get "http://localhost:4242"
    curl.response_code.should == 200
  end

  it "allows port to be overridden"

  it "returns a 500 error for unexpected requests"

  it "supports stubbing with uri only and default response"

  it "supports returning a custom response"

  it "supports stubbing with method, uri, body and headers"

  it "supports matching request body and headers against regular expressions"

  it "supports matching request body against a hash"

  it "supports matching custom request headers"

  it "supports matching multiple headers with the same name"

  it "supports matching requests against a block"

  it "supports basic auth"

  it "supports matching uris against regular expressions"

  it "supports matching query params using a hash"

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