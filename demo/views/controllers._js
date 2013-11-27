module Angular::PhonecatApp
  class PhoneListCtrl < Angular::Controller
    use :$scope, :$http

    $http.get('phones/phones.json').success { |data| $scope.phones = data }

    $scope.orderProp = 'age'
  end
end
