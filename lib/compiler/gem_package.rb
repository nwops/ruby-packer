# Copyright (c) 2017 Minqi Pan <pmq2001@gmail.com>
# 
# This file is part of Node.js Compiler, distributed under the MIT License
# For full terms see the included LICENSE file

require 'shellwords'
require 'tmpdir'
require 'fileutils'
require 'json'

class Compiler
  class GemPackage
    attr_reader :work_dir

    def initialize(options, utils)
      @module_name = options[:gem]
      @module_version = options[:gem_version]
      @work_dir = File.expand_path("#{@module_name}-#{@module_version}", options[:tmpdir])
      @utils = utils
    end

    def stuff_tmpdir
      @utils.rm_rf(@work_dir)
      @utils.mkdir_p(@work_dir)
      @utils.chdir(@work_dir) do
        # down the fuck
      end
    end

    def get_entrance(bin_name)
      @package_path = "node_modules/#{@module_name}/package.json"
      @bin_name = bin_name
      unless File.exist?(@package_path)
        raise Error, "No package.json exist at #{@package_path}."
      end
      @package_json = JSON.parse File.read @package_path
      @binaries = @package_json['bin']
      if @binaries
        STDERR.puts "Detected binaries: #{@binaries}"
      else
        raise Error, "No binaries detected inside #{@package_path}."
      end
      if @binaries.kind_of?(Hash) && @binaries[@bin_name]
        STDERR.puts "Using #{@bin_name} at #{@binaries[@bin_name]}"
        bin = @binaries[@bin_name]
      elsif @binaries.kind_of?(String)
        STDERR.puts "\n\nWARNING: Ignored supplied entrance `#{@bin_name}` since `bin` of package.json is a string\n\n"
        STDERR.puts "Using entrance #{@binaries}"
        bin = @binaries
      else
        raise Error, "No such binary: #{@bin_name}"
      end
      ret = File.expand_path("node_modules/#{@module_name}/#{bin}")
      unless File.exist?(ret)
        raise Error, "Npm install failed to generate #{ret}"
      end
      return File.expand_path("node_modules/#{@module_name}/#{bin}", @work_dir)
    end
  end
end