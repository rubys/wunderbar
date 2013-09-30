begin
  require 'minitest' 
rescue LoadError
end

begin
  require 'action_controller'
  require 'wunderbar/rails'

  class RailsTestController < ActionController::Base
    append_view_path File.expand_path(File.join File.dirname(__FILE__), 'views')

    def index
      @products = [Struct.new(:title,:quantity).new('Wunderbar',1_000)]
      render :index, :layout => 'application'
    end
  end

  WunderbarTestRoutes = ActionDispatch::Routing::RouteSet.new

  WunderbarTestRoutes.draw do
    resources :products
    match ':controller(/:action(/:id(.:format)))', :via => [:get, :post]
  end

rescue LoadError =>  exception
  require 'test/unit'
  ActionController = Module.new do
    const_set :TestCase, Class.new(Test::Unit::TestCase) {
      define_method(:default_test) {}
      define_method(:skip_reason) do
        exception.inspect
      end
    }
  end
end

class WunderbarOnRailsTest < ActionController::TestCase
  def setup
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
    @controller = RailsTestController.new
    @routes = WunderbarTestRoutes
  end

  def test_html_success
    get :index
    assert_response :success
    assert_select 'title', 'From Layout'
    assert_select 'meta[content="authenticity_token"]'
    assert_select 'meta[name="csrf-token"]'
    assert_select 'td', 'Wunderbar'
    assert_select 'td', '1 Thousand'
  end

  def test_json_success
    get :index, :format => 'json'
    assert_response :success
    response = JSON.parse(@response.body)
    assert_equal 'Wunderbar', response['products'][0]['title']
    assert_equal 1_000, response['products'][0]['quantity']
  end

  if superclass.superclass == Test::Unit::TestCase
    remove_method :setup
    attr_accessor :default_test
    public_instance_methods.grep(/^test_/).each do |method|
      remove_method method
    end
    unless instance_methods.grep(/^skip$/).empty?
      define_method(:test_rails) { skip skip_reason }
    end
  end
end
