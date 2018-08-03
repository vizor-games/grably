require 'grably/core/digest'

module Grably
  module Digest
    context 'digest equality' do
      context 'when digests has same arguments' do
        let(:args) do
          [Product.new('a.txt'), { mtime: nil, size: nil, md5: nil }]
        end

        it { expect(ProductDigest.new(*args)).to eq(ProductDigest.new(*args)) }
      end

      context 'when digests has different products' do
        let(:a) do
          [Product.new('a.txt'), { mtime: nil, size: nil, md5: nil }]
        end

        let(:b) do
          [Product.new('b.txt'), { mtime: nil, size: nil, md5: nil }]
        end

        it { expect(ProductDigest.new(*a)).to_not eq(ProductDigest.new(*b)) }
      end

      context 'when mtime was changed' do
        let(:a) do
          [Product.new('a.txt'), { mtime: 1, size: nil, md5: nil }]
        end

        let(:b) do
          [Product.new('a.txt'), { mtime: 3, size: nil, md5: nil }]
        end

        it { expect(ProductDigest.new(*a)).to_not eq(ProductDigest.new(*b)) }
      end

      context 'when size was changed' do
        let(:a) do
          [Product.new('a.txt'), { mtime: nil, size: 100, md5: nil }]
        end

        let(:b) do
          [Product.new('a.txt'), { mtime: nil, size: 200, md5: nil }]
        end

        it { expect(ProductDigest.new(*a)).to_not eq(ProductDigest.new(*b)) }
      end

      context 'when md5 was changed' do
        let(:a) do
          [Product.new('a.txt'), { mtime: nil, size: nil, md5: 'dead' }]
        end

        let(:b) do
          [Product.new('a.txt'), { mtime: nil, size: nil, md5: 'beef' }]
        end

        it { expect(ProductDigest.new(*a)).to_not eq(ProductDigest.new(*b)) }
      end
    end

    context 'digest diffs' do
      context 'when product list has missing entries' do
        let(:old_list) { %w(a.txt b.txt c.txt) }
        let(:new_list) { %w(a.txt b.txt) }

        it 'missing contains missing products' do
          missing, _added, _updated = Digest.diff_digests(*read_digest_sets(old_list, new_list))
          expect(missing).to match_array([Product.new('c.txt')])
        end

        it 'added empty' do
          _missing, added, _updated = Digest.diff_digests(*read_digest_sets(old_list, new_list))
          expect(added).to be_empty
        end

        it 'updated empty' do
          _missing, _added, updated = Digest.diff_digests(*read_digest_sets(old_list, new_list))
          expect(updated).to be_empty
        end
      end

      context 'when product list has updated entries' do
        let(:old_list) { [ProductDigest.new(Product.new('a.txt'), mtime: 0, size: 0, md5: 0)] }
        let(:new_list) { [ProductDigest.new(Product.new('a.txt'), mtime: 1, size: 0, md5: 0)] }

        it 'updated contains updated files' do
          _missing, _added, updated = Digest.diff_digests(old_list, new_list)
          expect(updated).to match_array(*Product.new('a.txt'))
        end
      end

      context 'when product list has new entries' do
        let(:old_list) { %w(a.txt b.txt c.txt) }
        let(:new_list) { %w(a.txt b.txt c.txt d.txt) }

        it 'missing empty' do
          missing, _added, _updated = Digest.diff_digests(*read_digest_sets(old_list, new_list))
          expect(missing).to be_empty
        end

        it 'added contains new products' do
          _missing, added, _updated = Digest.diff_digests(*read_digest_sets(old_list, new_list))
          expect(added).to match_array([Product.new('d.txt')])
        end

        it 'updated empty' do
          _missing, _added, updated = Digest.diff_digests(*read_digest_sets(old_list, new_list))
          expect(updated).to be_empty
        end
      end
    end
  end
end
