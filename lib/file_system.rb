require_relative "util"

class FileSystem
  include Util
  def mtime(file_path)
    return nil if file_path.nil? or !File.exist?(file_path)
    File.mtime(file_path)
  end

  def exists?(file_path)
    return File.exists?(file_path) if file_path
  end

end