require 'minitest/autorun'
require 'wunderbar'

class AssetTest < Minitest::Test
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
    @x.html {_head {_script}}
    assert_match %r{<script src="assets/jquery-min.js\?\d+"}, target
  end

  def test_noscript
    load 'wunderbar/jquery.rb'
    @x.html {_head}
    refute_match %r{<script src="assets/jquery-min.js\?\d+"}, target
  end

  def test_path_info_file
    load 'wunderbar/jquery.rb'
    @x.env['PATH_INFO']='/foo/bar/baz.html'
    @x.html {_head {_script}}
    assert_match %r{<script src="../../assets/jquery-min.js\?\d+"}, target
  end

  def test_path_info_directory
    load 'wunderbar/jquery.rb'
    @x.env['PATH_INFO']='/foo/bar/'
    @x.html {_head {_script}}
    assert_match %r{<script src="../../assets/jquery-min.js\?\d+"}, target
  end

  def test_base_in
    load 'wunderbar/jquery.rb'
    @x.html {_head {_base href: '/foo/bar/'; _script}}
    assert_match %r{<script src="../../assets/jquery-min.js\?\d+"}, target
  end

  def test_base_out
    load 'wunderbar/jquery.rb'
    @x.html {_head {_base href: '..'; _script}}
    assert_match %r{<script src="assets/jquery-min.js\?\d+"}, target
  end
end
