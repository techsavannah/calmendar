module ApplicationHelper
  def render_markdown(text)
    return "" if text.blank?
    renderer = Redcarpet::Render::HTML.new(safe_links_only: true, no_styles: true)
    markdown = Redcarpet::Markdown.new(renderer, autolink: true, tables: true, fenced_code_blocks: true, no_intra_emphasis: true)
    sanitize(markdown.render(text))
  end
end
