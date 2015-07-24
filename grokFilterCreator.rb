
class GrokCreator < Creator
    @@tags = []
    def self.setGrok(grok)
        @@grok = grok
    end
    def initialize(parent,lines,totalLineCount)
        super()
        @creating = parent.grok
        @creating.used = true
        @creating.grok = @@grok.clone
        @wrap = false
        @lines = lines
        @askedForTag = false
        @creating.totalLineCount = totalLineCount
    end
    def displayOptions

        lines = @lines.each_with_index.take(20)
        for line in lines
            puts (line[1] +1).to_s  + ": " + line[0].strip.to_s
        end


        puts ''
        puts '  Choose a line to match or type "tag" to change the tag'
    end
    def respond(input,root)
        if  (!(@askedForTag)) || input.start_with?('t')
            puts "Enter a unique tag for this filter (or leave blank if should always match)"
            tag = prompt
            if tag == ''
                tag = nil
            elsif @@tags.include? tag
                puts "Tag already used - are you sure you want to use it? (yes or no)"
                if prompt.start_with? 'y'
                    @creating.tag =tag
                end
            else
                @@tags.push(tag)
                @creating.tag =tag
            end

            if !@askedForTag
                @askedForTag = true
            else
                return false
            end
        end
        if @lines.count <1
            puts 'No lines to match'
            return true
        end
        line = @lines[input.to_i-1]
        if input.to_i < 1
            line = nil
        end
        if !line
            puts "  --Not valid"
            return false
        else
            creator = GrokPatternCreator.new(@creating,@@grok,line.strip,@lines)
            creator.run(root)
            return true
        end
    end
end

class GrokPatternCreator < Creator
    attr_accessor :variable_names
    def initialize(parent,grok,line,lines)
        super()
        @variable_names = []
        @creating = parent
        @grokguess = GrokGuess.new(grok)
        @creating.pattern = Regexp.escape(line).gsub("\\ "," ").gsub("\\.",".").gsub("\\-","-")
        @lines = lines.each_with_index.take(1000)
        @wrap = false
    end
    def displayOptions
        matchings = @lines.map{
            |line| @creating.matches(line[0].strip.to_s)
        }.compact
        @creating.totalHandled = matchings.count
        puts 'Currently matching ' + matchings.count.to_s + ' out of '+ @lines.count.to_s + ' lines (type "view" to view) '
        puts ''
        #Commented out as printing numbers above the text makes input more messy and confusing
    #    charIndexes = (1..@creating.pattern.each_char.count).map{|index|
    #            mod = (index % 10)
    #            if (mod == 1 || mod == 9) && index > 5
    #                char = "|"
    #            elsif mod == 0
    #                char = (index / 10).to_s
    #            else
    #                char = mod.to_s
    #            end
    #            char[0]
    #        }.join

        puts '----------------'
    #    puts indent + charIndexes
        puts @creating.pattern
        puts '----------------'
        puts '  Select section to replace with variable'
        puts 'Type "next" to return'
        puts '  Write first index then space then second index (0 to ' + (@creating.pattern.size-1).to_s + '), type the section to be replaced or press return to use assisted selection'
    end
    def respond(input,root)
        if input.start_with? 'v'
            puts 'Current matches:'
            @lines.map{|array| array[0].strip.to_s}.each{
                |line|
                puts ''
                puts line + ":"
                puts @creating.matches(line)
                puts ''
            }.compact
        end
        if input == 'next'
            return true
        end

        variable_start = -1
        variable_end = -1
        min_start = 0
        max_end = @creating.pattern.size-1

        if @creating.pattern.include? input
            variable_start = @creating.pattern.index input
            variable_end  = variable_start + @creating.pattern[input].size-1
        end

        if input == ""
            variable_start = -1
            repeat = true
            print 'Press return to move start forward type "back" to move backwards, type next to continue'
            selection = prompt
            while (selection == "") || (selection.start_with? 'b')
                if (selection == "")
                    variable_start = variable_start + 1
                else
                    variable_start = variable_start - 1
                end
                if variable_start < min_start
                    variable_start = min_start
                elsif variable_start> max_end
                    variable_start = max_end
                end
                print 'Starting selection with: "'+ @creating.pattern[variable_start] + '"   (index is '+ variable_start.to_s() +')'
                selection = prompt
            end
            variable_end = variable_start
            repeat = true
            print 'Press return to move end forward type "back" to move backwards, type next to continue'
            selection = prompt
            while (selection == "") || (selection.start_with? 'b')
                if (selection == "")
                    variable_end = variable_end + 1
                else
                    variable_end = variable_end - 1
                end
                if variable_end < variable_start
                    variable_end = variable_start
                elsif variable_end > max_end
                    variable_end = max_end
                end
                print 'Selection is: "'+ @creating.pattern[variable_start..variable_end]  + '"   (index is '+ variable_start.to_s() +' to '+ variable_end.to_s() +' )'
                selection = prompt
            end
        end

        if ! input =~ /[.'"\/]/
            array = input.split
            array = array.map{|x| x.to_i}
            if array.length == 2
                variable_start = array[0]
                variable_end = array[1]
            end
        end

        if variable_start >= min_start && variable_start <= variable_end && variable_end <= max_end
        variable = @creating.pattern[variable_start..variable_end]
            if variable && variable != ""
                creator = GrokVariableCreator.new(self, @creating.pattern,variable_start,variable_end, @grokguess)
                creator.run(root)
                output = creator.created
                if output
                    @creating.pattern[variable_start..variable_end] = output
                end
            else
                puts "--Retry--"
                puts ""
            end
        else
            puts "Out of range"
            puts "--Retry--"
            puts ""
        end
    end
end
class GrokVariableCreator < Creator
    def initialize(parent,line,variable_start,variable_end,grokguess)
        super()
        @displayStructure = false
        @parent = parent
        @matching = line[variable_start..variable_end]
        @line = line[variable_start .. -1]
        puts line
        puts @line
        @variable_end = variable_end - variable_start +1

        @grokguess = grokguess
        @grok = grokguess.grok

    end
    def displayOptions
        @fullmatches, @partmatches = @grokguess.discover(@line,@variable_end)

        puts ''
        puts '  Matching text: "'+ @matching +'" in "' + @line + '"'
        if @fullmatches.count > 0
            puts '  Autodiscovered patterns:'
            for pattern in @fullmatches.each_with_index.take(20)
                puts "      " + (pattern[1] +1).to_s  + ": " + pattern[0].strip.to_s
            end
            puts ''
            puts '  Type the number to use one or:'
        elsif @partmatches.count > 0
            puts '  Could not find a match but here are some partial matches to help you write your own pattern'
            puts @partmatches
        else
            puts "  No matches found - you will have to write your own pattern"
        end
        puts '   Choose "regex" or "grok"'
        puts ''
    end
    def respond(input,root)
        puts ''
        if input.start_with? 'r'
            puts "Enter regex"
            pattern = prompt
            puts 'Enter variable name '
            name = prompt
            if(@parent.variable_names.include?(name))
                puts "Name already used - are you sure you want to use it? (yes or no)"
                if !( prompt.start_with? 'y')
                    return false
                end
            else
                @parent.variable_names.push(name)
            end
            @creating = "(?<#{name}>#{pattern})"
        end
        if input.start_with? 'g'
            puts "Write grok pattern with variable captures"
            @creating = prompt
        end
        pattern = @fullmatches[input.to_i-1]
        if pattern && input.to_i > 0
            extension= ""
            if pattern == "GREEDYDATA"
                 extension = ' (use name "message" to allow branching)'
            end
            puts 'Type variable name' + extension
            name = prompt
            if(@parent.variable_names.include?(name))
                puts "Name already used - are you sure you want to use it? (yes or no)"
                if !( prompt.start_with? 'y')
                    return false
                end
            else
                @parent.variable_names.push(name)
            end
            if name != ""
                @creating = "%{#{pattern}:#{name}}"
            else
                @creating = "%{#{pattern}}"
            end
        end

        if @creating
            begin
                @grok.compile(@creating)
                match = @grok.match(@line)
                if match
                    if (match.match.end(0) == @variable_end) && (match.match.begin(0) == 0)
                        puts "Matched successfully - continuing"
                        return true
                    else
                        puts '  --Pattern "'+ @creating + '" does not exactly match "'+@matching+'" - try again'
                        puts '  --Pattern matched: ' + match.match[1]
                        puts '--Retry-- (or type next to continue anyway)'
                    end
                else
                    puts '  --Pattern "'+ @creating + '" does not match "'+@matching+'" - try again'
                    puts '--Retry-- (or type next to continue anyway)'
                end
            rescue RegexpError => error
                puts "  --Error compiling pattern: " + error
                puts "--Retry-- (or type next to continue anyway)"
            end
        end
        return false
    end
end
