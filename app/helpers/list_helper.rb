module ListHelper
  BADGE_COLORS = {
    purple:  "bg-purple-50 text-purple-700 ring-purple-600/20 dark:bg-purple-900/20 dark:text-purple-300 dark:ring-purple-400/20",
    blue:    "bg-blue-50 text-blue-700 ring-blue-600/20 dark:bg-blue-900/20 dark:text-blue-300 dark:ring-blue-400/20",
    info:    "bg-blue-50 text-blue-700 ring-blue-600/20 dark:bg-blue-900/20 dark:text-blue-300 dark:ring-blue-400/20",
    green:   "bg-green-50 text-green-700 ring-green-600/20 dark:bg-green-900/20 dark:text-green-300 dark:ring-green-400/20",
    success: "bg-green-50 text-green-700 ring-green-600/20 dark:bg-green-900/20 dark:text-green-300 dark:ring-green-400/20",
    red:     "bg-red-50 text-red-700 ring-red-600/20 dark:bg-red-900/20 dark:text-red-300 dark:ring-red-400/20",
    danger:  "bg-red-50 text-red-700 ring-red-600/20 dark:bg-red-900/20 dark:text-red-300 dark:ring-red-400/20",
    yellow:  "bg-yellow-50 text-yellow-700 ring-yellow-600/20 dark:bg-yellow-900/20 dark:text-yellow-300 dark:ring-yellow-400/20",
    warning: "bg-yellow-50 text-yellow-700 ring-yellow-600/20 dark:bg-yellow-900/20 dark:text-yellow-300 dark:ring-yellow-400/20",
    primary: "bg-primary-50 text-primary-700 ring-primary-600/20 dark:bg-primary-900/20 dark:text-primary-300 dark:ring-primary-400/20"
  }.freeze

  DEFAULT_BADGE_COLORS = "bg-zinc-50 text-zinc-600 ring-zinc-500/10 dark:bg-zinc-700 dark:text-zinc-300 dark:ring-zinc-400/20"

  # Collects title, meta, image, and badge declarations for a single list item.
  # Used internally by +item_list+; the block receives an ItemBuilder and the
  # current object.
  class ItemBuilder
    def initialize(object)
      @object = object
      @path = nil
      @image = nil
      @title = nil
      @metas = []
      @badges = []
      @modal = nil
    end

    def image(url = nil, alt: nil, fallback_icon: :photograph)
      @image = {
        url: url,
        alt: alt || @object.try(:name),
        fallback_icon: fallback_icon
      }
    end

    def title(text, classes: nil)
      @title = {
        text: text,
        classes: classes
      }
    end

    def meta(icon: nil, text:, classes: nil)
      @metas << {
        icon: icon,
        text: text,
        classes: classes
      }
    end

    def badge(text, type: :default, icon: nil)
      @badges << {
        text: text,
        type: type,
        icon: icon
      }
    end

    # Opens a modal dialog when the item is clicked instead of navigating.
    # Accepts the same options as +modal_dialog+ (id, title, size,
    # header_actions) plus either a partial or a block for content.
    def modal(id:, title:, size: :md, header_actions: nil, partial: nil, locals: {}, &block)
      @modal = {
        id: id,
        title: title,
        size: size,
        header_actions: header_actions,
        partial: partial,
        locals: locals,
        block: block_given? ? block : nil
      }
    end

    def modal? = @modal.present?

    def to_hash
      {
        object: @object,
        path: @path,
        image: @image,
        title: @title,
        metas: @metas,
        badges: @badges,
        modal: @modal
      }
    end
  end

  # Color classes for a badge type. Used by the item_list partial.
  def badge_color_classes(type)
    BADGE_COLORS[type] || DEFAULT_BADGE_COLORS
  end

  # Renders a navigable list of items with title, metadata, and badges.
  #
  # Items link to a path by default. Use +i.modal+ in the block to open a
  # modal dialog instead. Pass +path: false+ when all items use modals.
  #
  #   item_list(@problems) do |i, problem|
  #     i.title problem.title
  #   end
  #
  #   item_list(@problems, path: :edit_problem_path) do |i, problem| ... end
  #   item_list(@items, path: ->(item) { custom_path(item) }) do |i, item| ... end
  #
  #   item_list(@events, path: false) do |i, event|
  #     i.title event.name
  #     i.modal(id: "event-#{event.id}", title: "Detail") { ... }
  #   end
  def item_list(collection, path: nil, classes: nil, &block)
    return if collection.blank?

    items = collection.map do |object|
      builder = ItemBuilder.new(object)
      capture(builder, object, &block)
      builder.instance_variable_set(:@path, resolve_item_path(path, object)) unless builder.modal?
      builder.to_hash
    end

    render(partial: "shared/ui/item_list", locals: { items:, classes: })
  end

  private

  def resolve_item_path(path, object)
    case path
    when nil    then polymorphic_path(object)
    when false  then nil
    when Symbol then send(path, object)
    when Proc   then path.call(object)
    end
  end
end
