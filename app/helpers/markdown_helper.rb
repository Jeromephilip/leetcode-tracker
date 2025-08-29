module MarkdownHelper
  def markdown_to_html(text)
    return "" if text.blank?

    renderer = Redcarpet::Render::HTML.new(
      hard_wrap: true,
      link_attributes: { target: "_blank", rel: "noopener" },
      escape_html: true
    )

    markdown = Redcarpet::Markdown.new(renderer, {
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      strikethrough: true,
      superscript: true,
      underline: true,
      highlight: true,
      quote: true,
      footnotes: true
    })

    # Sanitize the HTML output for security
    sanitize(markdown.render(text), tags: %w[
      h1 h2 h3 h4 h5 h6
      p br div span
      strong b em i u del s mark
      ul ol li
      blockquote pre code
      table thead tbody tr th td
      a img
    ], attributes: %w[
      href src alt title target rel
      class id style
    ])
  end

  def markdown_preview(text, max_length: 100)
    return "" if text.blank?

    # Strip markdown formatting for preview
    preview = text.gsub(/[#*`~\[\]()]/m, "").strip
    preview = preview.gsub(/\n+/, " ").strip

    if preview.length > max_length
      preview[0...max_length] + "..."
    else
      preview
    end
  end
end
