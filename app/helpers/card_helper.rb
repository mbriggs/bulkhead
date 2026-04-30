module CardHelper
  # Class string for card containers — border, background, rounded corners,
  # and shadow by default. Pass `shadow: false` for cards nested inside other
  # cards to avoid stacking shadows.
  def card_classes(*classes, shadow: true)
    classnames("card", { "shadow" => shadow }, *classes)
  end

  # Class string for border-only panels — no background or shadow.
  # Use inside cards for tables, forms, and other edge-to-edge content.
  # Pass `overflow: :visible` when the panel contains dropdowns that
  # need to escape bounds.
  def panel_classes(*classes, overflow: :hidden)
    overflow_class = overflow == :visible ? "unclipped" : "clipped"
    classnames("panel", overflow_class, *classes)
  end

  # Class string for inset metadata blocks — grey background with a left
  # accent stripe. Use inside cards for definition lists, metadata, and
  # supplementary detail. Callers pass padding and extras as positional classes.
  def inset_classes(*classes)
    classnames("inset", *classes)
  end

  def card_header(title, subtitle = nil)
    content_tag :div, class: "card-header" do
      content = content_tag(:h3, title, class: "card-title")
      content += content_tag(:p, subtitle, class: "card-subtitle") if subtitle
      content
    end
  end

  class DetailCardBuilder
    def initialize
      @sections = []
    end

    def section(label, &block)
      @sections << [ label, block ]
    end

    def to_sections
      @sections
    end
  end

  def detail_card(title = nil, subtitle: nil, header_action: nil, shadow: true, &)
    card = DetailCardBuilder.new

    if block_given?
      capture do
        yield(card)
      end
    end

    sections = card.to_sections

    render partial: "shared/page/detail_card", locals: {
      title:,
      subtitle:,
      header_action:,
      shadow:,
      sections:
    }
  end
end
