require 'elasticsearch'
require 'elasticsearch/model'
require 'elasticsearch/persistence'

# Oink class that talks to es
class Oink
  @@repository = Elasticsearch::Persistence::Repository.new url: ENV['ELASTICSEARCH_URL'], log: true do

    # Set a custom index name
    index :my_oinks

    # Set a custom document type
    type  :oink

    # Specify the class to initialize when deserializing documents
    klass Oink

    settings number_of_shards: 1 do
      mapping do
        indexes :content,     analyzer: 'snowball'
        indexes :created_at,  type: 'date'
      end
    end

    def deserialize(oink)
      c = Oink.new
      c.id = oink['_source']['_id']
      c.content = oink['_source']['content']
      c.created_at = oink['_source']['created_at']
      c.handle = oink['_source']['handle']
      c
    end

    create_index!
  end

  attr_accessor :id, :content, :created_at, :handle

  attr_writer :content, :created_at, :handle

  def avatar_url
    "//robohash.org/#{handle}.png?size=144x144&amp;bgset=bg2"
  end

  def destroy
    @@repository.delete(@id, refresh: true)
  end

  def self.all()
    @@repository.search(
      query: { match_all: {} },
      sort: [{created_at: {order: 'desc'}}],
      size: 100
    )
  end

  def self.create(params)
    c = Oink.new
    c.id = SecureRandom.urlsafe_base64
    c.content = params[:content]
    c.created_at = Time.now.utc.iso8601
    c.handle = params[:handle].downcase
    @@repository.save(c, refresh:true)
    c
  end

  def self.find(id)
    @@repository.find(id)
  end

  def to_hash
    { "_id" => @id, "content" => @content, "created_at" => @created_at, "handle" => @handle }
  end
end