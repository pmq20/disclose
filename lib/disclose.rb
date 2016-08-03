require "disclose/version"
require "disclose/c"
require 'fileutils'
require 'shellwords'
require 'tmpdir'
require 'json'
require 'digest/md5'

class Disclose
  class Error < RuntimeError; end

  def self.usage
    %Q{
disclose v#{VERSION}

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
    chdir(@working_dir) do
      exe("tar hcf tar.tar -C \"#{@project_path}\" . -C \"#{File.dirname @node_path}\" \"#{File.basename @node_path}\"")
      exe("gzip tar.tar")
    end
  end

  def header!
    chdir(@working_dir) do
      exe("xxd -i tar.tar.gz > tar.h")
      @md5 = Digest::MD5.file('tar.h').to_s
    end
  end

  def c!
    chdir(@working_dir) do
      @binaries.each do |key,value|
        FileUtils.cp('tar.h', "#{key}.c")
        File.open("#{key}.c", "a") do |f|
          C.src(f, value, @md5, File.basename(@node_path))
        end

        exe("gcc #{ENV['DISCLOSE_COMPILER_ARG']} #{key}.c -o #{key} -lpthread")

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
