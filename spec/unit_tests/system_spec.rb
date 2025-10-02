require File.expand_path('../spec_helper', __FILE__)
require File.expand_path('../fake_http_response', __FILE__)

describe JenkinsApi::Client::System do
  context "With properly initialized Client" do
    before do
      mock_logger = Logger.new "/dev/null"
      mock_timeout = 300
      @client = double
      expect(@client).to receive(:logger).and_return(mock_logger)
      expect(@client).to receive(:timeout).and_return(mock_timeout)
      @system = JenkinsApi::Client::System.new(@client)
    end

    describe "InstanceMethods" do
      describe "#initialize" do
        it "initializes by receiving an instance of client object" do
          mock_logger = Logger.new "/dev/null"
          mock_timeout = 300
          expect(@client).to receive(:logger).and_return(mock_logger)
          expect(@client).to receive(:timeout).and_return(mock_timeout)
          JenkinsApi::Client::System.new(@client)
        end
      end

      describe "#quiet_down" do
        it "sends a request to put the server in quiet down mode" do
          expect(@client).to receive(:api_post_request).with("/quietDown")
          @system.quiet_down
        end
      end

      describe "#cancel_quiet_down" do
        it "sends a request to take the server away from quiet down mode" do
          expect(@client).to receive(:api_post_request).with("/cancelQuietDown")
          @system.cancel_quiet_down
        end
      end

      describe "#check_quiet_down" do
        it "checks if the server is presently in quiet down mode" do
          expect(@client).to receive(:logger).and_return(Logger.new "/dev/null")
          @root = JenkinsApi::Client::Root.new(@client)
          expect(@root).to receive(:quieting_down?)
          expect(@client).to receive(:root).and_return(@root)
          @system.check_quiet_down?
        end
      end

      describe "#restart" do
        it "sends a safe restart request to the server" do
          expect(@client).to receive(:api_post_request).with("/safeRestart")
          @system.restart(false)
        end
        it "sends a force restart request to the server" do
          expect(@client).to receive(:api_post_request).with("/restart")
          @system.restart(true)
        end
      end

      describe "#reload" do
        it "sends a reload request to the server" do
          expect(@client).to receive(:api_post_request).with("/reload")
          @system.reload
        end
      end

      describe "#list_users" do
        it "sends a request to list the users" do
          expect(@client).to receive(:api_get_request).with("/asynchPeople")
          expect(@system).to receive(:warn) # deprecated
          @system.list_users
        end
      end

      describe "#wait_for_ready" do
        it "exits if the response body doesn't have the wait message" do
          expect(@client).to receive(:get_root).and_return(FakeResponse.new)
          @system.wait_for_ready
        end
      end

    end
  end
end
