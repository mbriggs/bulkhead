module CardHelper
  # Class string for card containers — border, background, rounded corners,
  # and shadow by default. Pass `shadow: false` for cards nested inside other
  # cards to avoid stacking shadows.
  def card_classes(*classes, shadow: true)
    classnames("bg-white dark:bg-zinc-800 rounded-lg border border-zinc-200 dark:border-zinc-700", { "shadow-sm" => shadow }, *classes)
  end

  # Class string for border-only panels — no background or shadow.
  # Use inside cards for tables, forms, and other edge-to-edge content.
  # Pass `overflow: :visible` when the panel contains dropdowns that
  # need to escape bounds.
  def panel_classes(*classes, overflow: :hidden)
    overflow_class = overflow == :visible ? "overflow-visible" : "overflow-hidden"
    classnames("rounded-lg border border-zinc-200 dark:border-zinc-700", overflow_class, *classes)
  end

  # Class string for inset metadata blocks — grey background with a left
  # accent stripe. Use inside cards for definition lists, metadata, and
  # supplementary detail. Callers pass padding and extras as positional classes.
  def inset_classes(*classes)
    classnames("bg-zinc-50 dark:bg-zinc-800/80 border-l-2 border-zinc-300 dark:border-zinc-600", *classes)
  end

  def card_header(title, subtitle = nil)
    content_tag :div, class: "px-4 py-5 @sm:px-6 border-b border-zinc-200 dark:border-zinc-700" do
      content = content_tag(:h3, title, class: "text-lg leading-6 font-medium text-zinc-900 dark:text-zinc-100")
      content += content_tag(:p, subtitle, class: "mt-1 text-sm text-zinc-500 dark:text-zinc-400") if subtitle
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
