# GraphQL8::Batch

[![Build Status](https://travis-ci.org/Shopify/graphql8-batch.svg?branch=master)](https://travis-ci.org/Shopify/graphql8-batch)
[![Gem Version](https://badge.fury.io/rb/graphql8-batch.svg)](https://rubygems.org/gems/graphql8-batch)

Provides an executor for the [`graphql` gem](https://github.com/rmosolgo/graphql-ruby) which allows queries to be batched.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'graphql8-batch'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install graphql8-batch

## Usage

### Basic Usage

#### Schema Configuration

Require the library

```ruby
require 'graphql8/batch'
```

Define a custom loader, which is initialized with arguments that are used for grouping and a perform method for performing the batch load.

```ruby
class RecordLoader < GraphQL8::Batch::Loader
  def initialize(model)
    @model = model
  end

  def perform(ids)
    @model.where(id: ids).each { |record| fulfill(record.id, record) }
    ids.each { |id| fulfill(id, nil) unless fulfilled?(id) }
  end
end
```

Use `GraphQL8::Batch` as a plugin in your schema _after_ specifying the mutation
so that `GraphQL8::Batch` can extend the mutation fields to clear the cache after
they are resolved (for graphql >= `1.5.0`).

```ruby
class MySchema < GraphQL8::Schema
  query MyQueryType
  mutation MyMutationType

  use GraphQL8::Batch
end
```

For pre `1.5.0` versions:

```ruby
MySchema = GraphQL8::Schema.define do
  query MyQueryType

  GraphQL8::Batch.use(self)
end
```

#### Field Usage

The loader class can be used from the resolver for a graphql field by calling `.for` with the grouping arguments to get a loader instance, then call `.load` on that instance with the key to load.

```ruby
field :product, Types::Product, null: true do
  argument :id, ID, required: true
end

def product(id:)
  RecordLoader.for(Product).load(id)
end
```

The loader also supports batch loading an array of records instead of just a single record, via `load_many`. For example:

```ruby
field :products, [Types::Product, null: true], null: false do
  argument :ids, [ID], required: true
end

def products(ids:)
  RecordLoader.for(Product).load_many(ids)
end
```

Although this library doesn't have a dependency on active record,
the [examples directory](examples) has record and association loaders
for active record which handles edge cases like type casting ids
and overriding GraphQL8::Batch::Loader#cache_key to load associations
on records with the same id.

### Promises

GraphQL8::Batch::Loader#load returns a Promise using the [promise.rb gem](https://rubygems.org/gems/promise.rb) to provide a promise based API, so you can transform the query results using `.then`

```ruby
def product_title(id:)
  RecordLoader.for(Product).load(id).then do |product|
    product.title
  end
end
```

You may also need to do another query that depends on the first one to get the result, in which case the query block can return another query.

```ruby
def product_image(id:)
  RecordLoader.for(Product).load(id).then do |product|
    RecordLoader.for(Image).load(product.image_id)
  end
end
```

If the second query doesn't depend on the first one, then you can use Promise.all, which allows each query in the group to be batched with other queries.

```ruby
def all_collections
  Promise.all([
    CountLoader.for(Shop, :smart_collections).load(context.shop_id),
    CountLoader.for(Shop, :custom_collections).load(context.shop_id),
  ]).then do |results|
    results.reduce(&:+)
  end
end
```

`.then` can optionally take two lambda arguments, the first of which is equivalent to passing a block to `.then`, and the second one handles exceptions.  This can be used to provide a fallback

```ruby
def product(id:)
  # Try the cache first ...
  CacheLoader.for(Product).load(args["id"]).then(nil, lambda do |exc|
    # But if there's a connection error, go to the underlying database
    raise exc unless exc.is_a?(Redis::BaseConnectionError)
    logger.warn err.message
    RecordLoader.for(Product).load(args["id"])
  end)
end
```

## Unit Testing

Your loaders can be tested outside of a GraphQL8 query by doing the
batch loads in a block passed to GraphQL8::Batch.batch.  That method
will set up thread-local state to store the loaders, batch load any
promise returned from the block then clear the thread-local state
to avoid leaking state between tests.

```ruby
  def test_single_query
    product = products(:snowboard)
    title = GraphQL8::Batch.batch do
      RecordLoader.for(Product).load(product.id).then(&:title)
    end
    assert_equal product.title, title
  end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

See our [contributing guidelines](CONTRIBUTING.md) for more information.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
