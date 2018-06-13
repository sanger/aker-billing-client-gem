require 'spec_helper'
require 'billing_facade_client'
require 'active_model'

def mocked_model(cost_code)
  double('model', errors: {cost_code: []}, cost_code: cost_code)
end

RSpec.describe 'CostCodeValidator' do
  context 'validating models' do
    before(:each) do
      @validator = BillingFacadeClient::CostCodeValidator.new({:attributes => {}})
      allow(BillingFacadeClient).to receive(:validate_cost_code?).with('S1234').and_return(true)
      allow(BillingFacadeClient).to receive(:validate_cost_code?).with('G1234').and_return(true)
      allow(BillingFacadeClient).to receive(:validate_cost_code?).with('S1234-1').and_return(true)
      allow(BillingFacadeClient).to receive(:validate_cost_code?).with('S1234-2').and_return(false)
    end

    context "when cost code starts with \"S\"" do
      it "is valid" do
        @mock = mocked_model("S1234")
        @validator.validate(@mock)
        expect(@mock.errors[:cost_code].empty?).to eq(true)
      end
    end
    context "when cost code starts with \"G\"" do
      it "is valid" do
        @mock = mocked_model("G1234")
        @validator.validate(@mock)
        expect(@mock.errors[:cost_code].empty?).to eq(true)
      end
    end
    it "should validate a valid subproject" do
      @mock = mocked_model("S1234-1")
      @validator.validate(@mock)
      expect(@mock.errors[:cost_code].empty?).to eq(true)
    end

    it "should not validate invalid cost-codes" do
      @mock = mocked_model("S1234-2")
      @validator.validate(@mock)
      expect(@mock.errors[:cost_code].empty?).to eq(false)
    end

  end
  context '#validate_with_regexp?' do
    before do
      @validator = BillingFacadeClient::CostCodeValidator.new
    end

    context "when cost code begins with a valid letter" do
      it 'is valid' do
        ['S1234', 'G2378', 'N6366', 'T6473'].each do |cost_code|
          expect(@validator.validate_with_regexp?(cost_code)).to eq(true), "#{cost_code} expected to pass validation, but it failed"
        end
      end
    end

    it 'does not validate a wrong project cost_code' do
      ['S123', 's1234', 'S1234 ', ' S1234', 'S1234\t', 'S1234_'].each do |cost_code|
        expect(@validator.validate_with_regexp?(cost_code)).to eq(false), "#{cost_code} expected to fail validation, but it passed"
      end
    end

    it 'validates a subproject cost_code' do
      ['S1234-1', 'S1234-0', 'S1234-12'].each do |cost_code|
        expect(@validator.validate_with_regexp?(cost_code)).to eq(true), "#{cost_code} expected to pass validation, but it failed"
      end
    end

    it 'does not validate a wrong subproject cost_code' do
      ['S123-1', 's1234-1', 'S1234-1 ', ' S1234-1', 'S1234-1\t', 'S1234-', 'S1234-123', 'S1234-1-2'].each do |cost_code|
        expect(@validator.validate_with_regexp?(cost_code)).to eq(false), "#{cost_code} expected to fail validation, but it passed"
      end
    end

  end
end
