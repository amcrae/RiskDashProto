puts "Begin simple debug in ruby #{RUBY_VERSION}";
puts "script arguments #{ARGV}";
x = 0.0
for i in 1..5
    x = (x+1) ** 2
    puts "# #{i} : #{x}";
end
puts "Ended."
