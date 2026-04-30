require "test_helper"

class TonesTest < ActiveSupport::TestCase
  # --- normalize! (strict) ---

  test "normalize! returns canonical for canonical symbols" do
    Bulkhead::Tones::CANONICAL.each do |tone|
      assert_equal tone.to_s, Bulkhead::Tones.normalize!(tone)
    end
  end

  test "normalize! returns canonical for canonical strings" do
    Bulkhead::Tones::CANONICAL.each do |tone|
      assert_equal tone.to_s, Bulkhead::Tones.normalize!(tone.to_s)
    end
  end

  test "normalize! translates color aliases to canonical tones" do
    assert_equal "danger",  Bulkhead::Tones.normalize!(:red)
    assert_equal "success", Bulkhead::Tones.normalize!(:green)
    assert_equal "warning", Bulkhead::Tones.normalize!(:yellow)
    assert_equal "info",    Bulkhead::Tones.normalize!(:blue)
    assert_equal "primary", Bulkhead::Tones.normalize!(:indigo)
    assert_equal "default", Bulkhead::Tones.normalize!(:zinc)
    assert_equal "default", Bulkhead::Tones.normalize!(:gray)
    assert_equal "default", Bulkhead::Tones.normalize!(:grey)
  end

  test "normalize! translates status aliases" do
    assert_equal "danger", Bulkhead::Tones.normalize!(:error)
    assert_equal "info",   Bulkhead::Tones.normalize!(:notice)
  end

  test "normalize! is case-insensitive" do
    assert_equal "danger", Bulkhead::Tones.normalize!("Red")
    assert_equal "danger", Bulkhead::Tones.normalize!("RED")
    assert_equal "danger", Bulkhead::Tones.normalize!(:Red)
    assert_equal "info",   Bulkhead::Tones.normalize!("INFO")
  end

  test "normalize! raises on unknown tone" do
    err = assert_raises(ArgumentError) { Bulkhead::Tones.normalize!(:purple) }
    assert_match(/Unknown tone/, err.message)
  end

  test "normalize! raises on unrecognised string" do
    assert_raises(ArgumentError) { Bulkhead::Tones.normalize!("typo") }
  end

  test "normalize! raises on nil" do
    err = assert_raises(ArgumentError) { Bulkhead::Tones.normalize!(nil) }
    assert_match(/cannot be nil/, err.message)
  end

  # --- coerce (lenient with allowlist) ---

  test "coerce returns the canonical tone for an allowed canonical input" do
    assert_equal "danger", Bulkhead::Tones.coerce(:danger, allow: %i[danger success], default: :success)
  end

  test "coerce translates aliases before checking the allowlist" do
    assert_equal "danger", Bulkhead::Tones.coerce(:red, allow: %i[danger success], default: :success)
    assert_equal "success", Bulkhead::Tones.coerce("green", allow: %i[danger success default], default: :default)
  end

  test "coerce returns default for nil input" do
    assert_equal "default", Bulkhead::Tones.coerce(nil, allow: %i[danger success default], default: :default)
  end

  test "coerce returns default for an alias whose canonical isn't in allow" do
    assert_equal "default", Bulkhead::Tones.coerce(:warning, allow: %i[danger success default], default: :default)
  end

  test "coerce returns default for an unknown input" do
    assert_equal "default", Bulkhead::Tones.coerce(:bogus, allow: %i[danger success default], default: :default)
  end

  test "coerce passes through accent tones that are explicitly allowed" do
    accents = Bulkhead::Tones::CANONICAL + %i[purple high]
    assert_equal "purple", Bulkhead::Tones.coerce(:purple, allow: accents, default: :default)
    assert_equal "high",   Bulkhead::Tones.coerce(:high,   allow: accents, default: :default)
  end

  test "coerce is case-insensitive" do
    assert_equal "danger", Bulkhead::Tones.coerce("Red", allow: %i[danger], default: :danger)
  end

  test "coerce accepts string allow lists and string defaults" do
    assert_equal "danger", Bulkhead::Tones.coerce(:red, allow: %w[danger success], default: "success")
    assert_equal "danger", Bulkhead::Tones.coerce(nil, allow: %w[danger], default: "danger")
  end

  test "coerce raises when default is not in allow" do
    err = assert_raises(ArgumentError) do
      Bulkhead::Tones.coerce(:red, allow: %i[danger success], default: :info)
    end
    assert_match(/default/, err.message)
  end
end
