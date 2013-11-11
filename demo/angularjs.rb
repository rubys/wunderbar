#!/usr/bin/ruby
require 'wunderbar/angularjs'

_html ng_app: "PhonecatApp" do
  _title 'AnguarJS demonstration'
  _script do
    module Angular::PhonecatApp 
      class PhoneListCtrl < Angular::Controller 
        use :$scope
 
        $scope.phones = [
          {name: 'Nexus S',
           snippet: 'Fast just got faster with Nexus S.',
           age: 1},
          {name: "Motorola XOOM\u2122 with Wi-Fi",
           snippet: 'The Next, Next Generation tablet.',
           age: 2},
          {name: "Motorola XOOM\u2122",
           snippet: 'The Next, Next Generation tablet.',
           age: 3}
        ]

        $scope.orderProp = 'age'
      end
    end
  end

  _body ng_controller: 'PhoneListCtrl' do
    _ 'Search: '
    _input ng_model: 'query'
    __
    _ 'Sort by: '
    _select ng_model: 'orderProp' do
      _option 'Alphabetical', value: 'name'
      _option 'Newest', value: 'age'
    end

    _ul_ do
      _li ng_repeat: 'phone in phones | filter:query | orderBy:orderProp' do
        _ '{{phone.name}}'
        _p '{{phone.snippet}}'
      end
    end
  end
end
