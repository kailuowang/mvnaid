#!/usr/bin/env ruby
require File.join File.dirname(__FILE__), %w(.. lib jobs_runner)
directory = File.join(File.dirname(__FILE__) , "sandbox")

profile_properties_path =  File.join File.dirname(__FILE__), "sandbox", "build.properties"
runner = JobsRunner.new(ARGV,{profile_file: profile_properties_path, debug: true})

runner.settings[:project_repo].all_projects.each do |project|
  if project.vcs_adaptor.is_a?(SvnAdaptor)
    class << project.vcs_adaptor
      def get_svn_message project_directory, vcs_command
        filename = vcs_command.gsub(/\s/, "_")
        message_file = File.join File.dirname(__FILE__), project_directory, "#{filename}.msg"
        Action.new(@command_runner, project_directory,"#{vcs_command}").act
        return nil unless File.exist?(message_file)
        message = IO.readlines(message_file,'').join
        @message_displayer.trivial {message}
        message
      end

      def get_svn_status_message project_directory
        get_svn_message project_directory, status_command
      end

      def get_svn_info_message project_directory
        get_svn_message project_directory, info_command
      end

      def get_svn_update_message project_directory
        get_svn_message project_directory, update_command
      end
    end
  end
end


runner.run()
