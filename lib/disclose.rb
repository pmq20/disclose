require "disclose/version"
require 'shellwords'
require 'json'

class Disclose
  class Error < RuntimeError; end
  
  def initialize(node_path, project_path)
    @node_path = node_path
    @project_path = project_path
    @working_dir = Dir.mktmpdir
    parse_binaries!
  end
  
  def parse_binaries!
    @package_path = File.join(@project_path, 'package.json')
    raise "No package.json exist at #{@package_path}." unless File.exist?(@package_path)
    @package_json = JSON.parse File.read @package_path
    @binaries = @package_json['bin']
    if @binaries
      STDERR.puts "Detected binaries: #{@binaries}"
    else
      raise "No Binaries detected inside #{@package_path}."
    end
  end

  def run!
    tar!
    headers!
  end

  def tar!
    chdir(@project_path) do
      target = "#{@working_dir}/tar.tar"
      exe("tar cf #{Shellwords.escape(target)} . -C #{Shellwords.escape File.dirname @node_path} #{Shellwords.escape File.basename @node_path}")
    end
  end
  
  def headers!
    "TODO: headers!"
  end

  def usage
    'Usage: disclose <node_path> <project_path>'
  end

  private

  def exe(cmd)
    STDERR.puts "$ #{cmd}"
    STDERR.print `#{cmd}`
  end
  
  def chdir(path)
    STDERR.puts "$ cd #{path}"
    Dir.chdir(path) { yield }
    STDERR.puts "$ cd #{Dir.pwd}"
  end
end
