# frozen_string_literal: true

RSpec.describe Pidfd::Errors do
  describe '::BaseError' do
    it 'is a StandardError' do
      expect(described_class::BaseError.superclass).to eq(StandardError)
    end
  end

  describe '::PidfdOpenFailedError' do
    it 'is a BaseError' do
      expect(described_class::PidfdOpenFailedError.superclass).to eq(described_class::BaseError)
    end
  end

  describe '::PidfdSignalFailedError' do
    it 'is a BaseError' do
      expect(described_class::PidfdSignalFailedError.superclass).to eq(described_class::BaseError)
    end
  end
end
