module Bulkhead
  # Canonical tone vocabulary for component CSS classes.
  #
  # Two entry points:
  #
  #   Tones.normalize!(input)              raises on unknown — use when a tone
  #                                        is required and there's no fallback.
  #
  #   Tones.coerce(input, allow:, default:) validates against a per-component
  #                                        allowlist; returns default for nil
  #                                        or out-of-range inputs. Use when the
  #                                        component supports accent classes
  #                                        (e.g. badge.purple, badge.high) or
  #                                        a sensible fallback exists.
  #
  # Both entry points are case-insensitive and accept strings or symbols.
  module Tones
    CANONICAL = %i[primary secondary danger success warning info default].freeze

    # Color, status, and legacy-name aliases that map onto the canonical set.
    ALIASES = {
      red: :danger, green: :success, yellow: :warning, blue: :info,
      indigo: :primary, zinc: :default, gray: :default, grey: :default,
      error: :danger, notice: :info
    }.freeze

    # Strict: returns the canonical CSS class string or raises.
    def self.normalize!(input)
      raise ArgumentError, "Tone cannot be nil" if input.nil?
      key = input.to_s.downcase.to_sym
      tone = ALIASES[key] || (CANONICAL.include?(key) ? key : nil)
      raise ArgumentError, "Unknown tone: #{input.inspect}" unless tone
      tone.to_s
    end

    # Lenient: validates against `allow` (a list of canonical/accent tones the
    # component supports), falls back to `default` for nil or unknown inputs.
    def self.coerce(input, allow:, default:)
      allowed = allow.map { |t| t.to_s }
      default_str = default.to_s
      unless allowed.include?(default_str)
        raise ArgumentError, "default #{default.inspect} not in allow #{allow.inspect}"
      end
      return default_str if input.nil?

      key = input.to_s.downcase.to_sym
      tone = (ALIASES[key] || key).to_s
      allowed.include?(tone) ? tone : default_str
    end
  end
end
