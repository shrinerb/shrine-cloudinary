require "./config/credentials"

require "shrine"
require "shrine/storage/cloudinary"

require "./jobs/promote_job"
require "./jobs/delete_job"

Cloudinary.config(
  cloud_name: ENV.fetch("CLOUDINARY_CLOUD_NAME"),
  api_key:    ENV.fetch("CLOUDINARY_API_KEY"),
  api_secret: ENV.fetch("CLOUDINARY_API_SECRET"),
)

Shrine.storages = {
  cache: Shrine::Storage::Cloudinary.new(prefix: "cache"),
  store: Shrine::Storage::Cloudinary.new(prefix: "store"),
}

Shrine.plugin :sequel
Shrine.plugin :backgrounding
Shrine.plugin :logging

Shrine::Attacher.promote { |data| PromoteJob.perform_async(data) }
Shrine::Attacher.delete { |data| DeleteJob.perform_async(data) }
