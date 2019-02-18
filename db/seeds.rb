(1..10).each do |i|
  Item.create(name: "item #{i}", number: rand(100))
end
