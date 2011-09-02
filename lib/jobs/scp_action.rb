require_relative "action"
require File.join File.dirname(__FILE__), %w(.. util)

class ScpAction < Action
  attr_reader :settings
   def initialize params
     @settings = params
     remote_path = Util.remote_path(params[:destination_path], params[:username])
     command = "scp \"#{params[:source]}\" \"#{params[:username]}@#{params[:server]}:/#{remote_path}/#{params[:source]}\""
     super(params[:command_runner], params[:directory], command, {})
  end
end