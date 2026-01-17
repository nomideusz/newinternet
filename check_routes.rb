require_relative "config/environment"

puts "Session Routes:"
Rails.application.routes.routes.each do |route|
  if route.name.to_s.include?("session")
    puts "Name: #{route.name}, Path: #{route.path.spec}, Verb: #{route.verbs.first}"
  end
end
