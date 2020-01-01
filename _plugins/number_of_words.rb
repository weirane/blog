module Jekyll
  module Filters
    def number_of_words input
      cjk_regex = %r!\p{Han}|\p{Katakana}|\p{Hiragana}|\p{Hangul}!
      input.scan(cjk_regex).length + input.gsub(cjk_regex, ' ').split.length
    end
  end
end
