require 'open3'

BIN_PATH = File.join(File.dirname(__FILE__), "../mruby/bin/reddish")

def run(command)
  o, e, s = Open3.capture3(BIN_PATH, :stdin_data => command)
  Struct.new(:stdout, :stderr, :status).new(o, e, s)
end
