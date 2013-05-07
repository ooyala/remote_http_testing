require 'spec_helper'

def tester
  @tester ||= Class.new do
    include RemoteHttpTesting
    def server
      DEFAULT_SERVER
    end
    def exit(*args); end
  end.new
end

DEFAULT_SERVER = 'http://example.com'

describe RemoteHttpTesting do

  include RemoteHttpTesting
  let(:server) { DEFAULT_SERVER }

  describe ".ensure_reachable!" do

    before {
      tester.should_receive(:server_reachable?).
             with('http://example.com').
             and_return(reachable?)
    }
    subject { tester.ensure_reachable! tester.server }

    context "when reachable" do
      let(:reachable?) { true }
      it "silently continues" do
        tester.should_not_receive(:exit)
        tester.should_not_receive(:puts)
        subject
      end
    end
    context "when unreachable" do
      let(:reachable?) { false }
      it "bails" do
        tester.should_receive(:puts)
        tester.should_receive(:exit)
        subject
      end
    end
  end

  describe '#current_server' do
    subject { tester.current_server }
    context "with a temporary server set" do
      it "uses temporary server" do
        tester.use_server('http://yahoo.com') do
          tester.current_server.should == 'http://yahoo.com'
        end
      end
    end
    context "with no temporary server" do
      tester.current_server.should == DEFAULT_SERVER
    end
  end

  describe '#dom_response' do
    before { get '/index.html' }
    it "has DOM elements" do
      dom_response.css('#container').children.size.should > 2
    end
  end

  describe '#json_response' do
    before { get '/index.json' }
    it "is JSON data" do
      json_response[0]["id"].should == 222932599931285505
    end
  end

  describe '#response' do
    before { get '/index.html' }
    it "is the last HTTP response" do
      response.should be_a(Net::HTTPOK)
    end
  end
end
