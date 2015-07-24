require_relative  'tree'
require_relative  'filters'
require_relative 'grokguess'
require_relative 'filterCreators'
require "grok-pure"


def prompt()
    print "==>"
    input = $stdin.readline.strip
    puts ""
    return input
end

class RootCreator < Creator
    def initialize(lines,filePath)
        super()
        @creating = Root.new
        @creating.filePath = filePath
        @lines = lines
        @creating.outputLines = @lines
    end
    def displayOptions
        puts '  Type "add" to add a new branch or type a number to move to that branch'
    end
    def respond(input,root)
        if input.start_with? "a"
            creator = BranchCreator.new @creating
            creator.run(root)
        end
        if input.to_i > 0 && input.to_i <= @creating.branches.size
            creator = @creating.branches[input.to_i-1].creator
            creator.run(root)
        end
    end
    def run()
        super(@creating)
    end
end
class BranchCreator < Creator
    def initialize(parent)
        super()
        @creating = Branch.new(parent)
        if parent.is_a? Branch
            @creating.grok.parent_tag = parent.grok.tag
        end
        @lines = @creating.parent.unhandledLines
        parent.branches.push @creating

    end
    def displayOptions
        puts '  Type a filter(grok, drop, timestamp, convert) to create or replace a filter'
        puts '  Type "add" to add a new branch, type "delete" to remove this branch or type a number to move to that branch'
    end
    def respond(input,root)
        if input.start_with? "a"
            if @creating.outputLines.count > 0
                creator = BranchCreator.new(@creating)
                creator.run(root)
            else
                puts '  --Cannot create branch - this branch\'s grok filter doesn\'t allow continuation'
                puts '       (add a tag to the grok filter with the variable name message to allow )'
            end
        end
        if input.to_i > 0 && input.to_i <= @creating.branches.size
            creator = @creating.branches[input.to_i-1].creator
            creator.run(root)
        end
        if input.start_with? "delete"
            @creating.parent.branches.delete(@creating)
            return true
        end


        if input.start_with? "g"
            @creating.grok.usePercentage = false
            creator = GrokCreator.new(@creating, @lines,root.outputLines.count)
            creator.run(root)
            @creating.grok.usePercentage = true
        end
        if input.start_with? "d"
            creator = DropCreator.new(@creating)
            creator.run(root)
        end
        if input.start_with? "t"
            creator = DateCreator.new(@creating)
            creator.run(root)
        end
        if input.start_with? "c"
            creator = MutateCreator.new(@creating)
            creator.run(root)
        end
    end
end
