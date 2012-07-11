require "spec_helper"

class FakeClass
  include RemoteHttpTesting
end

describe RemoteHttpTesting do

  describe ".wrap_with_mock" do
    let!(:stub_response) { stub }
    let!(:stub_headers)  { stub }
    let(:subject) { FakeClass.new.wrap_with_mock(stub_response) }

    before do
      stub_response.should_receive(:code).and_return("200")
      stub_response.should_receive(:body).and_return("the body")
      stub_response.should_receive(:header).and_return(stub_headers)
      stub_headers.should_receive(:to_hash).and_return(:some => "header")
    end

    it "should create a new mock object" do
      subject.class.should == Rack::MockResponse
    end

    it "should populate the body" do
      subject.body.should == "the body"
    end

    it "should populate the headers" do
      subject.headers[:some].should == "header"
    end

    it "should populate the status" do
      subject.status.should == 200
      subject.should be_successful
    end
  end
end