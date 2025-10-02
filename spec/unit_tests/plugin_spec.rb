require File.expand_path('../spec_helper', __FILE__)
require "json"

describe JenkinsApi::Client::PluginManager do
  context "With properly initialized Client" do
    before do
      mock_logger = Logger.new "/dev/null"
      @client = double
      expect(@client).to receive(:logger).and_return(mock_logger)
      @plugin = JenkinsApi::Client::PluginManager.new(@client)
      @installed_plugins = load_json_from_fixture("installed_plugins.json")
      @available_plugins = load_json_from_fixture("available_plugins.json")
      @updatable_plugins = load_json_from_fixture("updatable_plugins.json")
    end

    describe "InstanceMethods" do
      describe "#initialize" do
        it "initializes by receiving an instane of client object" do
          mock_logger = Logger.new "/dev/null"
          expect(@client).to receive(:logger).and_return(mock_logger)
          JenkinsApi::Client::PluginManager.new(@client)
        end
      end

      describe "#list_installed" do
        it "lists all installed plugins in jenkins" do
          expect(@client).to receive(:api_get_request).
            with("/pluginManager", "tree=plugins[shortName,version]").
            and_return(@installed_plugins)
          plugins = @plugin.list_installed
          expect(plugins.class).to eq Hash
          expect(plugins.size).to eq @installed_plugins["plugins"].size
        end
        supported_filters = [
          :active, :bundled, :deleted, :downgradable, :enabled,
          :hasUpdate, :pinned
        ]
        supported_filters.each do |filter|
          it "lists all installed plugins matching filter '#{filter}'" do
            expect(@client).to receive(:api_get_request).
              with("/pluginManager",
                "tree=plugins[shortName,version,#{filter}]"
              ).and_return(@installed_plugins)
            expect(@plugin.list_installed(filter => true).class).to eq Hash
          end
        end
        it "lists all installed plugins matching multiple filters" do
          expect(@client).to receive(:api_get_request).
            with("/pluginManager", "tree=plugins[shortName,version,bundled,deleted]").
            and_return(@installed_plugins)
          expect(@plugin.list_installed(:bundled => true, :deleted => true).class).to eq Hash
        end
        it "raises an error if unsupported filter is specified" do
          expect { @plugin.list_installed(:unsupported => true) }.to raise_error(ArgumentError)
        end
      end

      describe "#list_available" do
        it "lists all available plugins in jenkins update center" do
          expect(@client).to receive(:api_get_request).
            with("/updateCenter/coreSource", "tree=availables[name,version]").
            and_return(@available_plugins)
          expect(@plugin.list_available.class).to eq Hash
        end
      end

      describe "#list_updates" do
        it "lists all available plugin updates in jenkins update center" do
          expect(@client).to receive(:api_get_request).
            with("/updateCenter/coreSource", "tree=updates[name,version]").
            and_return(@updatable_plugins)
          expect(@plugin.list_updates.class).to eq Hash
        end
      end

      describe "#install" do
        it "installs a single plugin given as a string" do
          expect(@client).to receive(:api_post_request).
            with("/pluginManager/install",
              {"plugin.awesome-plugin.default" => "on"}
            )
          @plugin.install("awesome-plugin")
        end
        it "installs multiple plugins given as an array" do
          expect(@client).to receive(:api_post_request).
            with("/pluginManager/install",
              {
                "plugin.awesome-plugin-1.default" => "on",
                "plugin.awesome-plugin-2.default" => "on",
                "plugin.awesome-plugin-3.default" => "on"
              }
            )
          @plugin.install([
            "awesome-plugin-1",
            "awesome-plugin-2",
            "awesome-plugin-3"
          ])
        end
      end

      describe "#uninstall" do
        it "uninstalls a single plugin given as a string" do
          expect(@client).to receive(:api_post_request).
            with("/pluginManager/plugin/awesome-plugin/doUninstall")
          @plugin.uninstall("awesome-plugin")
        end
        it "uninstalls multiple plugins given as array" do
          plugins = ["awesome-plugin-1", "awesome-plugin-2", "awesome-plugin-3"]
          plugins.each do |plugin|
            expect(@client).to receive(:api_post_request).
              with("/pluginManager/plugin/#{plugin}/doUninstall")
          end
          @plugin.uninstall(plugins)
        end
      end

      describe "#enable" do
        it "enables a single plugin given as a string" do
          expect(@client).to receive(:api_post_request).
            with("/pluginManager/plugin/awesome-plugin/makeEnabled")
          @plugin.enable("awesome-plugin")
        end
        it "enables multiple plugins given as array" do
          plugins = ["awesome-plugin-1", "awesome-plugin-2", "awesome-plugin-3"]
          plugins.each do |plugin|
            expect(@client).to receive(:api_post_request).
              with("/pluginManager/plugin/#{plugin}/makeEnabled")
          end
          @plugin.enable(plugins)
        end
      end

      describe "#disable" do
        it "disables a single plugin given as a string" do
          expect(@client).to receive(:api_post_request).
            with("/pluginManager/plugin/awesome-plugin/makeDisabled")
          @plugin.disable("awesome-plugin")
        end
        it "disabless multiple plugins given as array" do
          plugins = ["awesome-plugin-1", "awesome-plugin-2", "awesome-plugin-3"]
          plugins.each do |plugin|
            expect(@client).to receive(:api_post_request).
              with("/pluginManager/plugin/#{plugin}/makeDisabled")
          end
          @plugin.disable(plugins)
        end
      end

      describe "#restart_required?" do
        it "checks if restart is required after plugin install/uninstall" do
          expect(@client).to receive(:api_get_request).
            with("/updateCenter", "tree=restartRequiredForCompletion").
            and_return({"restartRequiredForCompletion" => true})
          expect(@plugin.restart_required?).to eq true
        end
      end
    end
  end
end
