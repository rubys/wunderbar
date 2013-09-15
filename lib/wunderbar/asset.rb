require 'fileutils'

module Wunderbar
  class Asset
    @@scripts = []
    @@stylesheets = []
    attr_reader :path, :source

    @@root = '../' * ENV['PATH_INFO'].to_s.count('/')

    def initialize(options)
      if (source=options[:file])
        options[:name] ||= File.basename(options[:file])
        @path = "assets/#{options[:name]}"
        dest = File.expand_path(@path)
        if not File.exist?(dest) or File.mtime(dest) < File.mtime(source)
          begin
            FileUtils.mkdir_p File.dirname(dest)
            FileUtils.cp source, dest, :preserve => true
          rescue
            @path = nil
            @source = File.read(source)
          end
        end
      end
    end

    def self.script(options)
      @@scripts << self.new(options)
    end

    def self.css(options)
      @@stylesheets << self.new(options)
    end

    def self.declarations
      Proc.new do 
        @@scripts.each do |script|
          if script.path
            _script :src => @@root+script.path
          elsif script.source
            _script script.source
          end
        end

        @@stylesheets.each do |stylesheet|
          if stylesheet.path
            _link :rel => "stylesheet", :href => @@root+stylesheet.path,
              :type => "text/css"
          elsif stylesheet.source
            _style stylesheet.source
          end
        end
      end
    end
  end
end
