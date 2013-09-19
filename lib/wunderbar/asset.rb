require 'fileutils'

module Wunderbar
  class Asset
    class << self
      # URI path prepended to individual asset path
      attr_accessor :path

      # location where the asset directory is to be found/placed
      attr_accessor :root
    end

    # asset file location
    attr_reader :path

    # asset contents
    attr_reader :contents

    def self.clear
      @@scripts = []
      @@stylesheets = []
    end

    clear

    @path = '../' * ENV['PATH_INFO'].to_s.count('/')
    @root = File.dirname(ENV['SCRIPT_FILENAME']) if ENV['SCRIPT_FILENAME']

    # Options: typically :name plus either :file or :contents
    #   :name => name to be used for the asset
    #   :file => source for the asset
    #   :contents => contents of the asset
    def initialize(options)
      source = options[:file] || __FILE__
      @contents = options[:contents]

      options[:name] ||= File.basename(options[:file]) if source

      if options[:name]
        @path = "assets/#{options[:name]}"
        dest = File.expand_path(@path, Asset.root || Dir.pwd)

        if not File.exist?(dest) or File.mtime(dest) < File.mtime(source)
          begin
            FileUtils.mkdir_p File.dirname(dest)
            if options[:file]
              FileUtils.cp source, dest, :preserve => true
            else
              open(dest, 'w') {|file| file.write @contents}
            end
          rescue
            @path = nil
            @contents ||= File.read(source)
          end
        end
      else
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
            _script :src => Asset.path+script.path
          elsif script.contents
            _script script.contents
          end
        end

        @@stylesheets.each do |stylesheet|
          if stylesheet.path
            _link :rel => "stylesheet", :href => Asset.path+stylesheet.path,
              :type => "text/css"
          elsif stylesheet.contents
            _style stylesheet.contents
          end
        end
      end
    end
  end
end
