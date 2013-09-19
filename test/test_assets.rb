require 'test/unit'
require 'rubygems'
require 'wunderbar'

class AssetTest < Test::Unit::TestCase
  def setup
    @x = Wunderbar::HtmlMarkup.new(Struct.new(:params).new({}))
    Wunderbar::Asset.clear
  end

  def target
    @x._.target!.join
  end

  def teardown
    Wunderbar::Asset.clear
    FileUtils.rm_rf 'assets'
  end

  def test_jquery
    load 'wunderbar/jquery.rb'
    @x.html {_head}
    assert_match %r{<script src="assets/jquery-min.js"}, target
  end

end
