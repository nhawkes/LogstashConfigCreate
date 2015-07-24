#Project structure:
#
# => tree.rb contains code to store the tree structure and to write it out as a logstash config or tree structure. filters.rb contains the filters for a branch
# => Everthing has a command line interface provided by its creator. Creators call other creators to build up structure. treeCreators.rb contains the creators for roots and branches, filterCreators.rb (and grokFilterCreator) contains the interface to create filters.
# => grokguess.rb provides the pattern discovery for grok



require 'json'
require_relative 'treeCreators'
lines = []
if !ARGV[0]
    puts 'No logfile specified'
    puts ''
    puts 'Command synopsis: ruby main.rb [logfile.log]'
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
