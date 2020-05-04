module Kramdown
  module Utils
    module Html
      def fix_cjk_line_break(str)
        regex = /([\p{Han}\p{Hiragana}\p{Katakana}」』）】》〉，、：；。？！]+)\n([\p{Han}\p{Hiragana}\p{Katakana}「『（【《〈]+)/u
        while str.gsub!(regex, '\1\2')
        end
        str
      end
    end
  end
  module Converter
    class Html < Base
      def convert_text(el, _indent)
        escaped = escape_html(el.value, :text)
        fix_cjk_line_break(escaped)
      end
    end
  end
end
