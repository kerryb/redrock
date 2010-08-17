require File.expand_path("../spec_helper", __FILE__)

describe RedRock do
  it "listens on port 4242 by default" do
    stub_request :any, "localhost:4242"
    curl = Curl::Easy.http_get "http://localhost:4242"
    curl.response_code.should == 200
  end
end
