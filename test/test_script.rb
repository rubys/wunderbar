require 'test/unit'
require 'wunderbar/script'

class ScriptTest < Test::Unit::TestCase
  def test_script
    @x = Wunderbar::HtmlMarkup.new(Struct.new(:params).new({}))
    @x.html do 
      _script {alert :foo}
    end
    assert_match %r[<script lang="text/javascript">alert\("foo"\)</script>],
      @x._.target!
  end
end
