class Creator
    attr_reader :created
    def initialize
        @wrap = true
        @displayStructure = true
        @help =
        """
        This program generates logstash configuration files.

        Add branches for each type of log output and add branches to those branches for each subtype
        Adding sub-branches adds conditional statements to the output config

        Use a grok filter to get data from the log message
        Use a greedydata at the end of a grok filter to allow subtypes

        Typing just the first letter of a command will usually work (e.g. n for next, g for grok)


        """
    end
    def run(root)
        @finished = false

        if @creating.respond_to? :creator=
            @creating.creator = self
        end

        while ! @finished
            if @wrap
                if @displayStructure
                    self.writeStructure(root)
                end
                puts ''
                puts '[Type "next" to continue, type "help" for help, type "list" to list current tree or:]'
            end
            self.displayOptions()
            input = prompt
            if @wrap && input.start_with?("n")
                @finished = true
            elsif @wrap && input.start_with?("l")
                self.writeStructure(root)
                @finished = false
            elsif @wrap && input.start_with?("h")
                puts @help
                @finished = false
            else
                @finished = (self.respond(input,root) == true)
            end
        end
        @created = @creating
        if @created == root
            puts "OUTPUT:"
            puts ""
            @created = root.writeOutput()
        end
    end
    def writeStructure(root)
        puts "Current structure:"
        puts ""
        canHighlight = @creating.respond_to? :hightlight=
        if canHighlight
            @creating.hightlight = true
            root.writeStructure()
            @creating.hightlight = false
        else
            root.writeStructure()
        end
    end
end
class DropCreator < Creator
    def initialize(parent)
        super()
        @creating = parent.drop
        @wrap = false
    end
    def displayOptions
        puts ''
        puts '  Drop and ignore all messages that match the grok in this branch? (yes/no)'
    end
    def respond(input,root)
        if input.start_with? 'y'
            @creating.used = true
        else
            @creating.used = false
        end
        return true
    end
end
class DateCreator < Creator
    def initialize(parent)
        super()
        @creating = parent.date
        @match = nil
        @field = nil
        @grokFilter = parent.grok
    end
    def displayOptions
        puts ''
        puts '  Type "field" to set field or "match" to set match'
    end
    def respond(input,root)
        if input.start_with? 'f'
            puts '  What field contains the timestamp?'
            @field = prompt
        elsif input.start_with? 'm'
            puts '''
            Letter	Date or Time Component	Presentation	Examples
            G	Era designator	Text	AD
            y	Year	Year	1996; 96
            Y	Week year	Year	2009; 09
            M	Month in year	Month	July; Jul; 07
            w	Week in year	Number	27
            W	Week in month	Number	2
            D	Day in year	Number	189
            d	Day in month	Number	10
            F	Day of week in month	Number	2
            E	Day name in week	Text	Tuesday; Tue
            u	Day number of week (1 = Monday, ..., 7 = Sunday)	Number	1
            a	Am/pm marker	Text	PM
            H	Hour in day (0-23)	Number	0
            k	Hour in day (1-24)	Number	24
            K	Hour in am/pm (0-11)	Number	0
            h	Hour in am/pm (1-12)	Number	12
            m	Minute in hour	Number	30
            s	Second in minute	Number	55
            S	Millisecond	Number	978
            z	Time zone	General time zone	Pacific Standard Time; PST; GMT-08:00
            Z	Time zone	RFC 822 time zone	-0800
            X	Time zone

            Or use
            "ISO8601" - to parse any valid ISO8601 timestamp, such as 2011-04-19T03:44:01.103Z
            "UNIX" - to parse unix time in seconds since epoch
            "UNIX_MS" - to parse unix time in milliseconds since epoch

            '''
            puts ''
            puts '  Write the match string using this format'
            puts 'For example: "2001.07.04 AD at 12:08:56 PDT => "yyyy.MM.dd G \'at\' HH:mm:ss z"'
            puts ''

            fieldKey = nil
            for key in @grokFilter.keys
                if key.end_with? ':' + @field
                    fieldKey = key
                end
            end
            if @grokFilter.lastCaptures[fieldKey]
                puts "Example of timestamp to match:"
                puts @grokFilter.lastCaptures[fieldKey]
                puts ''
            end



            @match = prompt
        end

        if @field && @match
            @creating.field = @field
            @creating.match = @match
            @creating.used = true
        end
    end
end
class MutateCreator < Creator
    def initialize(parent)
        super()
        @creating = parent.mutate
        @creating.used = true
        @wrap = false
    end
    def displayOptions
        puts ''
        puts '  Type a fieldname to convert type'
    end
    def respond(input,root)
        puts "Choose a type to convert to (either integer, float, string)"
        type = prompt
        if type.start_with? 'i'
            @creating.mutates[input] = "integer"
            return true
        end
        if type.start_with? 'f'
            @creating.mutates[input] = "float"
            return true
        end
        if type.start_with? 's'
            @creating.mutates[input] = "float"
            return true
        end
        return false
    end
end
require_relative 'grokFilterCreator'
