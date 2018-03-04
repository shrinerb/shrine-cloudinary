require "bundler/setup"

require "minitest/autorun"
require "minitest/pride"

require "shrine/storage/cloudinary"
require "dotenv"

require "stringio"
require "forwardable"

Dotenv.load!

Cloudinary.config(
  cloud_name: ENV.fetch("CLOUDINARY_CLOUD_NAME"),
  api_key:    ENV.fetch("CLOUDINARY_API_KEY"),
  api_secret: ENV.fetch("CLOUDINARY_API_SECRET"),
)

class FakeIO
  def initialize(content)
    @io = StringIO.new(content)
  end

  extend Forwardable
  delegate %i[read rewind eof? close size] => :@io
end

class Minitest::Test
  def image
    FakeIO.new(File.read("test/fixtures/image.jpg"))
  end
end
