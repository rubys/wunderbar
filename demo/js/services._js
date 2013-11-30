module Angular::PhonecatServices
  Phone = $resource.new 'phones/:phoneId.json', {},
    query: {method: 'GET', params: {phoneId: 'phones'}, isArray: true}
end
