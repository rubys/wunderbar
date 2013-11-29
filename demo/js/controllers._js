module Angular::PhonecatControllers
  class PhoneListCtrl < Angular::Controller
    use :$scope, :$http

    $http.get('phones/phones.json').success { |data| $scope.phones = data }

    $scope.orderProp = 'age'
  end

  class PhoneDetailCtrl < Angular::Controller
    use :$scope, :$routeParams, :$http

    $http.get("phones/#{$routeParams.phoneId}.json").
      success { |data| $scope.phone = data }
  end
end
