require 'nokogiri'

def process(content)
  content = Nokogiri::HTML(content)
  content.css('a.external').each do |a|
    a.remove_class('external')
    a.set_attribute('target', '_blank')
    a.inner_html += " <i class='fas fa-external-link-square-alt'></i>"
  end
  content.to_s
end

Jekyll::Hooks.register :posts, :post_render do |page|
  page.output = process(page.output)
end
