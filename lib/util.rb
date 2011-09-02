require "yaml"

module Util
  MISSING_BUILD_PROPERTIES = "Please setup your build.properties file, you can use build.properties.template as an example"
  BUILD_PROPERTIES_FILE = "build.properties"

  def load_yaml_hash(file_path)
    return {} if file_path.nil? || !File.exist?(file_path)
    YAML::load_file(file_path)
  end

  def save_yaml(file_path, object)
    File.open(file_path, "w") {|file| file.puts(object.to_yaml) }
  end

  def self.separator
    separator = File::ALT_SEPARATOR || File::SEPARATOR
    return separator
  end

  def self.path(directory)
    return directory unless directory.is_a? String
    directory.gsub(File::SEPARATOR, Util.separator())
  end

  def path(directory)
    Util.path(directory)
  end

#  copied from internet :)
  def Util.load_properties(properties_filename, error_msg = nil )
    error_msg ||= "Please make sure you have \"#{properties_filename}\" with your settings."
    raise error_msg  unless File.exist?(properties_filename) 
    properties = {}
    File.open( properties_filename, 'r') do |properties_file|
      properties_file.read.each_line do |line|
        line.strip!
        if (line[0] != ?# and line[0] != ?=)
          i = line.index('=')
          if (i)
            key = line[0..i - 1].strip
            value =  line[i + 1..-1].strip
          else
            key = line
          end
          properties[key.to_sym] = value
        end
      end
    end
    properties
  end

  def Util.load_build_properties( profile_file_path = File.join(File.dirname(__FILE__), ".." , BUILD_PROPERTIES_FILE))
    self.load_properties(profile_file_path, MISSING_BUILD_PROPERTIES)
  end

  def Util.remote_path(remote_path, username)
    remote_path.gsub("~", "home/#{username}")
  end

end