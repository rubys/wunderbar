module Angular::PhonecatFilters
  filter :checkmark do |input|
    return input ? "\u2713" : "\u2718"
  end
end
