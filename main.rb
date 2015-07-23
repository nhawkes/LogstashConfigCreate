require 'json'
require_relative 'treeCreators'
lines = []
if !ARGV[0]
    puts 'No logfile specified'
    puts 'e.g: ruby main.rb logfile.log'
    exit
end

File.open(ARGV[0]) do |f|
    lines = f.readlines
    puts "---START OF LOG---"
    puts lines
    puts "---END OF LOG---"
    puts " "
end

grok = Grok.new
grok.add_patterns_from_file("patterns/base")
GrokCreator.setGrok(grok)
creator = RootCreator.new(lines,File.expand_path(ARGV[0]))
text = creator.run()
toWrite = ARGV[0].tr(".","") + ".conf"
File.open(toWrite,'w') do |f|
    f.puts text
end
puts "Written config file to " + toWrite
