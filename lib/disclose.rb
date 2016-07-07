require "disclose/version"
require "disclose/c"
require 'fileutils'
require 'shellwords'
require 'tmpdir'
require 'json'

class Disclose
  class Error < RuntimeError; end

  def self.usage
    %q{
Usage: disclose [node_path] [project_path]
  e.g. disclose /usr/local/bin/node /usr/local/lib/node_modules/coffee-script
    }.strip
  end
  
  def initialize(node_path, project_path)
    @node_path = node_path
    @project_path = project_path
    @working_dir = Dir.mktmpdir
    parse_binaries!
  end
  
  def parse_binaries!
    @package_path = File.join(@project_path, 'package.json')
    raise Error, "No package.json exist at #{@package_path}." unless File.exist?(@package_path)
    @package_json = JSON.parse File.read @package_path
    @binaries = @package_json['bin']
    if @binaries
      STDERR.puts "Detected binaries: #{@binaries}"
    else
      raise Error, "No Binaries detected inside #{@package_path}."
    end
  end

  def run!
    tar!
    header!
    c!
  end

  def tar!
    chdir(@project_path) do
      @tar_path = "#{@working_dir}/tar.tar"
      exe("tar cf #{Shellwords.escape(@tar_path)} . -C #{Shellwords.escape File.dirname @node_path} #{Shellwords.escape File.basename @node_path}")
    end
  end
  
  def header!
    chdir(@working_dir) do
      exe("xxd -i tar.tar > tar.h")
    end
  end
  
  def c!
    chdir(@working_dir) do
      @binaries.each do |key,value|
        FileUtils.cp('tar.h', "#{key}.c")
        File.open("#{key}.c", "a") do |f|
          f.puts C.src(value)
        end
        exe("cc #{key}.c -o #{key}")

        puts "======= Success ======="
        puts File.join(@working_dir, key)
        puts "======================="
      end
    end
  end

  private

  def exe(cmd)
    STDERR.puts "$ #{cmd}"
    STDERR.print `#{cmd}`
    raise Error, "#{cmd} failed!" unless $?.success?
  end
  
  def chdir(path)
    STDERR.puts "$ cd #{path}"
    Dir.chdir(path) { yield }
    STDERR.puts "$ cd #{Dir.pwd}"
  end
end
