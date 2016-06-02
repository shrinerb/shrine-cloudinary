require "./config/shrine"

class ImageUploader < Shrine
  plugin :remove_attachment
end
