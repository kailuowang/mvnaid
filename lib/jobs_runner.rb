require File.join File.dirname(__FILE__), "jobs","build_projects_job"
require File.join File.dirname(__FILE__), "jobs","run_jetty_job"
require File.join File.dirname(__FILE__), "jobs","vcs_update_job"
require File.join File.dirname(__FILE__), "jobs","info_job"
require File.join File.dirname(__FILE__), "jobs","vcs_commit_job"
require File.join File.dirname(__FILE__), "jobs","vcs_checkout_job"
require File.join File.dirname(__FILE__), "jobs","remote_clean_job"
require File.join File.dirname(__FILE__), "jobs","display_local_changes_job"
require File.join File.dirname(__FILE__), "jobs","deploy_job"
require File.join File.dirname(__FILE__), "project_repo"
require File.join File.dirname(__FILE__), "user_interface"
require File.join File.dirname(__FILE__), "option_parser"
require File.join File.dirname(__FILE__), "message_displayer"
require File.join File.dirname(__FILE__), "commit_message_builder"
require File.join File.dirname(__FILE__), "util"
require "set"

class JobsRunner
  TEAM_PROFILES_DIRECTORY = "team_profiles"
  attr_reader :settings #exposed for testing purpose

  def build_properties
    Util.load_build_properties(@settings[:profile_file])
  end

  def configs_directory
    profile_name = build_properties[:profile]
    File.join File.dirname(@settings[:profile_file]), TEAM_PROFILES_DIRECTORY, profile_name
  end

  
  def initialize(args, settings = {})
    @no_args = args.nil? || args.empty?

    @options = OptionParser.parse(args)
    default_settings = { debug: false}
    @settings = default_settings.merge settings
    @settings[:verbose] = @options.verbose
    @settings[:quiet] = @options.quiet
    @settings[:profile_file] ||=  File.join File.dirname(__FILE__), ".." , Util::BUILD_PROPERTIES_FILE
    @settings[:configs_directory] ||= configs_directory
    @settings[:user_interface] ||= UserInterface.new
    @settings[:message_displayer] = MessageDisplayer.new(@settings[:verbose], @settings[:quiet])
    @settings[:command_runner] ||= CommandRunner.new(@settings[:debug], @settings[:message_displayer] )
    @settings[:modification_status_checker] ||= ModificationStatusChecker.new(message_displayer: @settings[:message_displayer])
    project_deploy_info_filename = build_properties[:deploy_info_filename] || "project_deploy_info"
    @settings[:project_repo] ||= ProjectRepo.new( build_log_file_path: @settings[:configs_directory] + "/project_build_log.yml",
                                                  deploy_info_file_path: @settings[:configs_directory] + "/#{project_deploy_info_filename}.yml",
                                                  projects_info_file_path: @settings[:configs_directory] + "/projects_info.yml",
                                                  modification_status_checker: @settings[:modification_status_checker],
                                                  modification_status_checker: @settings[:modification_status_checker],
                                                  command_runner: @settings[:command_runner],
                                                  message_displayer: @settings[:message_displayer],
                                                  build_properties: build_properties)
    @settings[:commit_message_builder] ||= CommitMessageBuilder.new(@settings[:user_interface],
                                                                    @settings[:configs_directory] + "/prompt_answers.yml")
  end

  def run()
    message_displayer = @settings[:message_displayer]
    command_runner = @settings[:command_runner]
    project_repo = @settings[:project_repo]
    if @no_args
      message_displayer.important {"building all projects..."}
      BuildProjectsJob.new(nil,project_repo,command_runner,message_displayer, false).run
    end

    if @options.clean
      project_repo.clean_project_log
      message_displayer.important {"removed all build time"}
      end


    unless @options.push_back_build_time.nil?
      project_repo.push_back_build_time(@options.push_back_build_time)
      message_displayer.important {"all build_time pushed back by #{@options.push_back_build_time} hours"}
    end
    if @options.update
      VcsUpdateJob.new(project_repo,command_runner, message_displayer).run
    end
    if @options.info
      InfoJob.new(project_repo, message_displayer).run
    end
    if @options.local_changes
      DisplayLocalChangesJob.new(project_repo, message_displayer).run
    end
    if @options.remote_clean
      RemoteCleanJob.new(project_repo, message_displayer).run
    end
    if @options.checkout
      VcsCheckoutJob.new(project_repo, FileSystem.new, message_displayer).run
    end
    if @options.build_project_names.size > 0
      BuildProjectsJob.new(@options.build_project_names,project_repo,command_runner,message_displayer).run
    end
    if @options.build_all
      BuildProjectsJob.new(project_repo.all_projects,project_repo,command_runner,message_displayer).run
    end
    if @options.deploy
      DeployJob.new(project_repo, command_runner, message_displayer).run
    end
    if @options.commit
      VcsCommitJob.new( project_repo: project_repo,
                        command_runner: command_runner,
                        user_interface: @settings[:user_interface],
                        message_displayer: message_displayer,
                        commit_message_builder: @settings[:commit_message_builder]).run
    end
    unless @options.jetty_run_project_name.nil?
      RunJettyJob.new(@options.jetty_run_project_name,project_repo, command_runner,message_displayer).run
    end
    if @options.restart
      DeployJob.new(project_repo, command_runner, message_displayer).restart_sandbox
    end
  end

end
