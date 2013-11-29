module Angular::PhonecatControllers
  class PhoneListCtrl < Angular::Controller
    $http.get('phones/phones.json').success { |data| $scope.phones = data }

    $scope.orderProp = 'age'
  end

  class PhoneDetailCtrl < Angular::Controller
    $http.get("phones/#{$routeParams.phoneId}.json").
      success { |data| $scope.phone = data }
  end
end
