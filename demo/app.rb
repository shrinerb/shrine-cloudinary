require "roda"
require "tilt/erb"

require "./models/album"
require "./models/photo"

class CloudinaryDemo < Roda
  plugin :all_verbs
  plugin :indifferent_params
  plugin :render
  plugin :partials
  plugin :static, [*`ls public`.split("\n").map{|f|"/#{f}"}]

  use Rack::MethodOverride

  route do |r|
    @album = Album.first || Album.create(name: "My Album")

    r.root do
      view(:index)
    end

    r.put "album" do
      @album.update(params[:album])
      r.redirect r.referer
    end

    r.post "album/photos" do
      photo = @album.add_photo(params[:photo])
      partial("photo", locals: {photo: photo, idx: @album.photos.count})
    end
  end
end
