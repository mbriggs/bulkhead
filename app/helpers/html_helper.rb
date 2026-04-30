module HtmlHelper
  # Returns the default class unless the caller explicitly opts out with false.
  #   default_class(nil, "form") => "form"
  #   default_class("wide", "form") => "wide"
  #   default_class(false, "form") => nil
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
        arg.each { |key, value| classes << key.to_s if value }
      when Array
        classes << classnames(*arg)
      end
    end

    classes.compact.uniq.join(" ")
  end
end
