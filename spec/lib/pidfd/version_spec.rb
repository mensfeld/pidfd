# frozen_string_literal: true

RSpec.describe "Pidfd::VERSION" do
  it "has a version number" do
    expect(Pidfd::VERSION).not_to be_nil
  end

  it "is a string" do
    expect(Pidfd::VERSION).to be_a(String)
  end

  it "follows semantic versioning" do
    expect(Pidfd::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end
end
