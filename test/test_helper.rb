require "minitest/autorun"
require "minitest/pride"

require "shrine/storage/cloudinary"
require "dotenv"

Dotenv.load!

Cloudinary.config(
  cloud_name: ENV.fetch("CLOUDINARY_CLOUD_NAME"),
  api_key:    ENV.fetch("CLOUDINARY_API_KEY"),
  api_secret: ENV.fetch("CLOUDINARY_API_SECRET"),
)

class Minitest::Test
  def image
    File.open("test/fixtures/image.jpg")
  end
end
