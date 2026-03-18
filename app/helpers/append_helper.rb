module AppendHelper
  def append_data!(name, value, kwargs)
    data = kwargs[:data] ||= {}
    data[name] = value.to_s
    data
  end

  def append_value!(name, *)
    append_data!("#{name.to_s.dasherize}-value", *)
  end

  def append_class!(kwargs, *)
    kwargs[:class] = classnames(kwargs[:class], *)
  end

  def disable_prefetch!(kwargs)
    append_data!("turbo_prefetch", false, kwargs)
  end

  def append_confirm!(kwargs, confirm)
    if !confirm
      return
    end

    # Use Turbo's native confirmation instead of custom controller
    kwargs[:data] ||= {}
    kwargs[:data][:turbo_confirm] = confirm
    disable_prefetch!(kwargs)
  end

  def append_controller!(ctrl, kwargs)
    kwargs[:data] ||= {}
    controller = kwargs[:data].delete(:controller)
    case controller
    when String
      controller = [ controller, ctrl ]
    when Array
      controller = controller + [ ctrl ]
    else
      controller = ctrl
    end

    kwargs[:data][:controller] = controller
    kwargs
  end
end
