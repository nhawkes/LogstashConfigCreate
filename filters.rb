class Creatable
    attr_accessor :creator
end

class Filter < Creatable
    attr_accessor :used
    def ifUsedWriteOutput(writer)
        if @used
            self.writeOutput(writer)
        end
    end
    def ifUsedWriteStructure(writer)
        if @used
            self.writeStructure(writer)
        end
    end
end

class GrokFilter < Filter
    attr_accessor :tag, :tag_failure, :grok, :keys, :parent_tag, :totalLineCount, :totalHandled, :usePercentage
    attr_reader :pattern, :lastCaptures
    def initialize()
        @pattern = ""
        @tag_failure = true
        @keys = []
        @lastCaptures = {}
        @totalLineCount = 1
        @totalHandled = 0
        @usePercentage = false
    end
    def writeOutput(writer)
        writer.write('grok {')
        writer.indent

        writer.write('match => {')
        writer.indent
        match = @pattern
        writer.write('"message" => "' + match + '"')
        writer.unindent
        writer.write('}')


        if self.can_branch?
            writer.write('overwrite => [ "message" ]')
        end
        if @tag
            writer.write('add_tag => ["' + @tag + '"]')
            if @parent_tag && @parent_tag != ''
                writer.write('remove_tag => ["' + @parent_tag + '"]')
            end
            writer.write('tag_on_failure => []')
        end
        writer.unindent
        writer.write('}')
    end
    def writeStructure(writer)
        match = "->" + @pattern
        if match.include? "%{GREEDYDATA:message}"
            match["%{GREEDYDATA:message}"] = "{{...}}"
        end
        percentHandled = ((@totalHandled.to_f / @totalLineCount.to_f) * 100.0).round(1)
        if @tag
            tag = '  ('+ @tag + ')'
        else
            tag = ""
        end
        writer.write(match + tag + "    [#{percentHandled}%]")
    end
    def pattern=(pattern)
        @pattern = pattern
        @grok.compile(@pattern)
        @keys = []
    end
    def matches (line)
        begin
            if @grok
                @grok.compile(@pattern)
                match = @grok.match(line.strip)
                if match
                    captures = {}
                    match.match.regexp.named_captures.each {|name, indexes|
                        if name.include? ":"
                            shortname = name.gsub(/(.*):/,"")
                            captures[shortname] =  match.match.captures[indexes[0]-1]
                        end
                    }
                    @lastCaptures = captures
                    if captures.keys.count > 0
                        @keys = captures.keys
                    end
                    return captures
                end
            end
        rescue RegexpError => error
            puts "----Grok error----"
        end
        return nil
    end
    def can_branch?
        @keys.include? 'message'
    end
end
class DropFilter < Filter
    def writeOutput(writer)
        writer.write('drop {}')
    end
    def writeStructure(writer)
        writer.write("  IGNORE MESSAGE")
    end
end
class DateFilter < Filter
    attr_accessor :match, :field
    def writeOutput(writer)
        writer.write('date {')
        writer.indent
        writer.write('match => [ "'+field+'", "'+ match+'"]')
        writer.write('remove_field => [ "'+ field + '" ]')
        writer.unindent
        writer.write('}')
    end
    def writeStructure(writer)
        writer.write("Set timestamp from " + @field)
    end
end
class MutateFilter < Filter
    attr_accessor :mutates
    def initialize
        @mutates = {}
    end
    def writeOutput(writer)
        writer.write('mutate {')
        writer.indent
        for k, v in @mutates
            writer.write('convert => [ "'+k+'", "'+v+'"]')
        end
        writer.unindent
        writer.write('}')
    end
    def writeStructure(writer)
        writer.write("Convert type(s): " + @mutates.keys.join(", "))
    end
end
