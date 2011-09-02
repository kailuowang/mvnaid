require File.join File.dirname(__FILE__), %w(.. lib jobs_runner)
require File.join File.dirname(__FILE__), %w(.. lib util)

describe JobsRunner do
  describe "config_directory" do
    it "should return directory based on properties file" do
      Util.should_receive(:load_properties).
                with(Util::BUILD_PROPERTIES_FILE, Util::MISSING_BUILD_PROPERTIES).
                at_least(1).
                and_return({profile: "thoughtdocs_svn"})

      jobs_runner = JobsRunner.new([], {profile_file: Util::BUILD_PROPERTIES_FILE})
      jobs_runner.configs_directory.should == File.join(".", JobsRunner::TEAM_PROFILES_DIRECTORY,"thoughtdocs_svn")
    end
  end
end
