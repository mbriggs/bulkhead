module HtmlHelper
  # Returns the default class unless the caller explicitly opts out with false.
  #   default_class(nil, "max-w-prose")   => "max-w-prose"
  #   default_class("max-w-lg", "max-w-prose") => "max-w-lg"
  #   default_class(false, "max-w-prose") => nil
  def default_class(value, default)
    return nil if value == false
    value || default
  end

  def classnames(*args)
    classes = []

    args.each do |arg|
      case arg
      when String, Symbol
        classes << arg.to_s
      when Hash
        arg.each do |key, value|
          classes << key.to_s if value
        end
      when Array
        classes << classnames(*arg)
      end
    end

    if classes.length == 1
      return classes.first
    end

    classes.compact.uniq.join(" ")
  end
end
