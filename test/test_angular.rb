require 'minitest/autorun'
require 'wunderbar/angularjs'

class AngularjsMarkupTest < Minitest::Test
  def test_template
    @x = Wunderbar::HtmlMarkup.new(Struct.new(:params).new({}))
    @x.html do
      _ng_template id: 'templateContent.html' do
        _h1 'Hello World!'
      end
    end
    target = @x._.target!
    assert_match %r{<script .*id="templateContent.html".*>}, target
    assert_match %r{<script .*type="text/ng-template".*>}, target
    assert_match %r{<h1>Hello World!</h1>}, target
  end
end
