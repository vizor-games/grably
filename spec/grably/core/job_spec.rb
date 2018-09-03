require 'rspec'
require 'fileutils'
require 'tmpdir'

require 'grably/core'
require 'grably/job'
include Grably::Core

module WordCountResources
  VALUES = {
    a: %w(one two three),
    b: %w(four five),
    c: %w(six),
    e: %w(seven)
  }.freeze

  def create_srcs(dir)
    VALUES.each do |name, values|
      write_file(dir, name, values)
    end
  end

  def write_file(dir, name, values)
    IO.write(File.join(dir, "#{name}.txt"), values.join(' '))
  end

  def expected_result(values = VALUES)
    values.values.flatten.length
  end

  def values
    VALUES
  end
end

module WordCountTest
  include WordCountResources

  class BaseWordCountJob
    include Grably::Job

    attr_reader :executed
    srcs :files

    def initialize(*_args)
      @executed = false
      @processed_files = []
      @executed = false
    end

    def process_files(products)
      products.inject({}) do |acc, product|
        # Keep product as key
        acc.update(product => count_words(product.src))
      end
    end

    def count_words(file)
      IO.read(file).scan(/\w+/).length
    end

    def write_result
      @executed = true # Mark as executed
      word_count = meta.values.inject(:+)
      out = job_path('count.txt')
      IO.write(out, word_count.to_s)
      out
    end
  end

  # Incremental word count job
  class IncrementalWordCount < BaseWordCountJob
    # Values for assertions
    attr_reader :executed, :processed_files

    def build
      # # Will return 3 groups of products
      # deleted, added, updated = src_changes(:files)
      # # Keep all but deleted
      # cached_values = meta.reject { |k, _v| deleted.include?(k) }

      # # Scan updates
      # updated_counts = process_files(added + updated)

      # # For unit test only. Track processed files
      # @processed_files = updated_counts.keys.map(&:src)

      # # Override stale values
      # @meta = cached_values.update(updated_counts)

      # write_result
    end
  end

  # Plain word count job
  class WordCount < BaseWordCountJob
    def build
      meta.clear
      meta.update(process_files(files))
      write_result
    end
  end

  def create_incremental_job
    IncrementalWordCount.new
  end

  def create_job
    WordCount.new
  end

  def do_setup
    @wd = Dir.mktmpdir
    @original_wd = Dir.pwd
    Dir.chdir(@wd)
    @srcs = File.join(@wd, 'srcs')
    @job_dir = File.join(@wd, 'job')
    [@srcs, @job_dir].each { |d| FileUtils.mkdir_p(d) }
    create_srcs(@srcs)
  end

  def do_cleanup
    Dir.chdir(@original_wd)
    FileUtils.rm_rf(@wd)
  end
end

describe 'Job' do
  include WordCountTest

  before(:all) do
    do_setup
  end

  before(:each) do
    # Create job with fresh state before each test.
    @job = create_job
  end

  it 'should return correct answer' do
    result = @job.run(nil, @job_dir, files: { @srcs => '**/*.txt' }).first
    expect(IO.read(result.src).to_i).to eq(expected_result)
  end

  it 'should not be executed without changes' do
    result = @job.run(nil, @job_dir, files: { @srcs => '**/*.txt' }).first
    expect(IO.read(result.src).to_i).to eq(expected_result)
    expect(@job.executed).to be(false)
  end

  it 'should rebuild when file changed' do
    file_name = :c

    # Store old values
    old_values = values[:c]
    new_values = old_values * 3

    # Write new values
    write_file(@srcs, file_name, new_values)

    # Check
    result = @job.run(nil, @job_dir, files: { @srcs => '**/*.txt' }).first
    expect(@job.executed).to be(true)
    expect(IO.read(result.src).to_i).to eq(expected_result(values.merge(c: new_values)))

    # Return everything back
    write_file(@srcs, file_name, old_values)
  end

  it 'should rebuild when file deleted' do
    remove_file = :c
    all_except = values.reject { |k, _v| k == remove_file }
    expected = expected_result(all_except)
    result = @job.run(nil, @job_dir, files: { @srcs => "!**/#{remove_file}.txt" }).first
    expect(@job.executed).to be(true)
    expect(IO.read(result.src).to_i).to eq(expected)
  end

  it 'should rebuild when file added' do
    result = @job.run(nil, @job_dir, files: { @srcs => '**/*.txt' }).first
    expect(@job.executed).to be(true)
    expect(IO.read(result.src).to_i).to eq(expected_result)
  end

  after(:all) do
    do_cleanup
  end
end

# describe 'Incremental job' do
#   include WordCountTest

#   before(:all) do
#     do_setup
#   end

#   before(:each) do
#     # Create job with fresh state before each test.
#     @job = create_incremental_job
#   end

#   it 'should return correct answer' do
#     result = @job.execute(@srcs => '**/*.txt').first
#     expect(IO.read(result.src).to_i).to eq(expected_result)
#   end

#   it 'should not be executed without changes' do
#     result = @job.execute(@srcs => '**/*.txt').first
#     expect(IO.read(result.src).to_i).to eq(expected_result)
#     expect(@job.executed).to be(false)
#   end

#   it 'should rebuild only changed files' do
#     file_name = :c

#     # Store old values
#     old_values = values[:c]
#     new_values = old_values * 3

#     # Write new values
#     write_file(@srcs, file_name, new_values)

#     # Check
#     result = @job.execute(@srcs => '**/*.txt').first
#     expect(@job.processed_files).to match_array([File.join(@srcs, "#{file_name}.txt")])
#     expect(IO.read(result.src).to_i).to eq(expected_result(values.merge(c: new_values)))

#     # Return everything back
#     write_file(@srcs, file_name, old_values)
#   end

#   it 'should track deletions' do
#     remove_file = :c
#     all_except = values.reject { |k, _v| k == remove_file }
#     expected = expected_result(all_except)
#     result = @job.execute(@srcs => "!**/#{remove_file}.txt").first
#     expect(@job.processed_files).to be_empty
#     expect(IO.read(result.src).to_i).to eq(expected)
#   end

#   it 'should track additions' do
#     result = @job.execute(@srcs => '**/*.txt').first
#     expect(@job.processed_files).to match_array([File.join(@srcs, 'c.txt')])
#     expect(IO.read(result.src).to_i).to eq(expected_result)
#   end

#   after(:all) do
#     do_cleanup
#   end
# end
