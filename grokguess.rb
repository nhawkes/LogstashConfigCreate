#Code 'borrowed' and edited from:
#https://github.com/jordansissel/ruby-grok/blob/master/examples/pattern-discovery.rb
class GrokGuess
  attr_reader :grok
  def initialize(grok)
    @grok = grok
  end
  def discover(text,match_end)
    groks = {}
    @grok.patterns.each do |name, expression|
      grok = Grok.new
      grok.patterns.merge!(@grok.patterns)
      grok.compile("%{#{name}}")
      groks[name] = grok
    end

    patterns = groks.sort { |a, b| complexity(b.last.expanded_pattern) <=> complexity(a.last.expanded_pattern) }
    fullmatches = []
    partmatches = []
    patterns.each do |name, grok|
        m = grok.match(text)
        next unless m
        partmatches.push(name)
        if (m.match.end(0) == match_end) && (m.match.begin(0) == 0)
            fullmatches.push(name)
        end
    end
    return fullmatches, partmatches
  end
  def complexity(expression)
    score = expression.count("|") # number of branches in the pattern
    score += expression.length # the length of the pattern
  end
end
#End of 'borrowing'
