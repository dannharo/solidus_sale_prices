require 'spec_helper'

describe Spree::SalePrice do

  it 'can start and end never' do
    sale_price = build(:sale_price)
    sale_price.start

    expect(sale_price).to be_enabled
    expect(sale_price.end_at).to be(nil)
  end

  it 'can start and then end at a specific time' do
    sale_price = build(:sale_price)
    sale_price.start(1.day.from_now)

    expect(sale_price).to be_enabled
    expect(sale_price.end_at).to be_within(1.second).of(1.day.from_now)
  end

  it 'can stop' do
    sale_price = build(:active_sale_price)
    sale_price.stop

    expect(sale_price).not_to be_enabled
    expect(sale_price.end_at).to be_within(1.second).of(Time.now)
  end

  it 'can create a money price ready to display' do
    sale_price = build(:active_sale_price)
    money = sale_price.display_price

    expect(money).to be_a Spree::Money
    expect(money.money.amount.to_f).to be_within(0.1).of(sale_price.calculated_price.to_f)
    expect(money.money.currency).to eq(sale_price.currency)
  end

  context 'when the associated price is destroyed' do
    subject { create(:sale_price) }
    let(:price) { subject.price }

    before do
      price.destroy
      subject.reload
    end

    it 'still can find the price via price_with_deleted association' do
      expect(subject.price).to be_nil
      expect(subject.price_with_deleted).to eql price
    end
  end

  describe '#variant association' do
    context 'when the price has been soft-deleted' do
      before do
        sale = create :sale_price
        sale.price.destroy
      end

      it 'preloads the variant via SQL also for soft-deleted records' do
        records = Spree::SalePrice.with_deleted.includes(:variant)
        expect(records.first.variant).to be_present
      end
    end
  end

  context 'touching associated product when destroyed' do
    subject { -> { sale_price.reload.destroy } }
    let!(:product) { sale_price.product }
    let(:sale_price) { Timecop.travel(1.day.ago) { create(:sale_price) } }

    it { is_expected.to change { product.reload.updated_at } }

    context 'when product association has been destroyed' do
      before { sale_price.variant.update_columns(product_id: nil) }

      it 'does not touch product' do
        expect(subject).not_to change { product.reload.updated_at }
      end
    end

    context 'when associated variant has been destroyed' do
      before { sale_price.variant.destroy }

      it 'does not touch product' do
        expect(subject).not_to change { product.reload.updated_at }
      end
    end

    context 'when associated price has been destroyed' do
      before { sale_price.price.destroy }

      it 'does not touch product' do
        expect(subject).not_to change { product.reload.updated_at }
      end
    end
  end

  describe '.ordered' do
    subject { described_class.ordered }

    let!(:forever) { create(:sale_price) }
    let!(:future) { create(:sale_price, start_at: 10.days.from_now) }
    let!(:past) { create(:sale_price, start_at: 10.days.ago) }
    let!(:present) { create(:active_sale_price) }

    it { is_expected.to match [forever, past, present, future] }
  end

  describe '.for_product' do
    subject { described_class.for_product(product) }

    before { product.put_on_sale(10.95) }

    context 'without variants' do
      let(:product) { create(:product) }

      it { is_expected.to match product.master.sale_prices }
    end

    context 'with variants' do
      let(:variant) { create(:variant) }
      let(:product) { variant.product }

      it { is_expected.to match variant.sale_prices + product.master.sale_prices }
    end
  end
end
