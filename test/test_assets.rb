require 'test/unit'
require 'rubygems'
require 'wunderbar'

class AssetTest < Test::Unit::TestCase
  def setup
    scope = Struct.new(:params, :env).new({}, {'DOCUMENT_ROOT' => Dir.pwd})
    @x = Wunderbar::HtmlMarkup.new(scope)
    Wunderbar::Asset.clear
  end

  def target
    @x._.target!
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

  def test_base
    load 'wunderbar/jquery.rb'
    @x.html {_head {_base href: '/foo/bar/'}}
    assert_match %r{<script src="../../assets/jquery-min.js"}, target
  end
end
