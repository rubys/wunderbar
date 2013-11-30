module Angular::PhonecatControllers
  controller :PhoneListCtrl do
    $scope.phones = Phone.query()
    $scope.orderProp = 'age'
  end

  controller :PhoneDetailCtrl do
    $scope.phone = Phone.get(phoneId: $routeParams.phoneId) do |phone|
      $scope.mainImageUrl = phone.images[0]
    end

    def $scope.setImage(imageUrl)
      $scope.mainImageUrl = imageUrl
    end
  end
end
