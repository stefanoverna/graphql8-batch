require_relative 'test_helper'

class GraphQL8::Batch::ExecutorTest < Minitest::Test
  def setup
    GraphQL8::Batch::Executor.current = GraphQL8::Batch::Executor.new
  end

  def teardown
    GraphQL8::Batch::Executor.current = nil
  end

  def test_loading_flag_when_not_loading
    assert_equal false, GraphQL8::Batch::Executor.current.loading
  end

  class TestLoader < GraphQL8::Batch::Loader
    attr_reader :number, :loading_in_perform

    def initialize(number)
      @number
    end

    def perform(keys)
      @loading_in_perform = GraphQL8::Batch::Executor.current.loading
      keys.each { |key| fulfill(key, key) }
    end
  end

  def test_loading_flag_in_loader_perform
    loader = TestLoader.for(1)
    loader.load(:key).sync
    assert_equal true, loader.loading_in_perform
  end

  def test_loading_flag_in_callback
    loading_in_callback = nil
    TestLoader.for(1).load(:key).then { loading_in_callback = GraphQL8::Batch::Executor.current.loading }.sync
    assert_equal false, loading_in_callback
  end

  def test_loading_flag_in_nested_load
    loader2 = nil
    TestLoader.for(1).load(:key).then do
      loader2 = TestLoader.for(2)
      loader2.load(:key2)
    end.sync
    assert_equal true, loader2.loading_in_perform
  end

  def test_end_batch_with_no_executor
    GraphQL8::Batch::Executor.current = nil

    assert_raises(GraphQL8::Batch::NoExecutorError) do
      GraphQL8::Batch::Executor.end_batch
    end
  end
end
