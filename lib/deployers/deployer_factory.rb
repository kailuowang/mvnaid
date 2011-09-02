class DeployerFactory
  attr_reader :general

  def initialize params = {}
    @build_properties = params[:build_properties]

    @general = get_general params
    @project_specifics = params[:project_specifics]
    @message_displayer = params[:message_displayer]
    @command_runner = params[:command_runner]

    @project_repo = params[:project_repo]
  end

  def get_general params
    general = params[:general] || {}
    if @build_properties
      general[:username] = @build_properties[:username] if @build_properties.has_key?(:username)
      general[:server] = @build_properties[:server] if @build_properties.has_key?(:server)
      general[:destination_path] = @build_properties[:sandbox_lib_path] if @build_properties.has_key?(:sandbox_lib_path)
      general[:restart_script_path] = @build_properties[:restart_script_path] if @build_properties.has_key?(:restart_script_path)
    end
    general
  end


  def create_deployer(project)
    project_specific = @project_specifics[project.name]
    if project_specific.nil?
      @message_displayer.trivial{"deploy info missing for project #{project.name}"}
      return nil
    end
    project_specific = @general.merge(project_specific)
    username = project_specific[:username]
    server =  project_specific[:server]
    case(project_specific[:type])
      when :presentation
        if server
          PresentationDeployer.new( project: project,
                                    destination_path: filter_path(project_specific[:destination_path]),
                                    server: server,
                                    command_runner: @command_runner,
                                    destination_username: username,
                                    remote_post_update_command: project_specific[:remote_post_update_command])
        else
          nil
        end
      when :binary
        create_binary_deployer(project, project_specific, server, username)
      when :remote
        if server
          RemoteDeployer.new(command_runner: @command_runner, remote_location: project_specific[:remote_location], server: server, username: username)
        else
           nil
        end
      else
        raise "unrecognized type #{project_specific[:type]}"
    end
  end


  def get_binary_path(project_specific)
    binary_path = project_specific[:binary_file_path]
    if binary_path.is_a? Array
       binary_path.map {|p| filter_path(p)}
    else
      filter_path(binary_path)
    end
  end

  def create_binary_deployer(project, project_specific, server, username)
    binary_path = get_binary_path(project_specific)
    BinaryDeployer.new(project: project,
            command_runner: @command_runner,
            destination_path: project_specific[:destination_path],
            server: server,
            destination_username: username,
            project_repo: @project_repo,
            binary_file_path: binary_path )
  end

  def filter_path(raw_path)
    return nil if raw_path.nil?
    path = raw_path.clone
    find_variables(raw_path).each do |variable|
      raise "#{variable} is not defined in the build.properties file" unless @build_properties.has_key? variable      
      path.gsub!(/\$\{#{variable}\}/, @build_properties[variable])
    end
    path
  end

  def find_variables(string)
    string.scan(/\$\{(.+?)\}/).collect do |var|
       var[0].to_sym
    end
  end
end