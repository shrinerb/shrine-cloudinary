# Shrine::Storage::Cloudinary

Provides [Cloudinary] storage for [Shrine].

Cloudinary provides storage and advanced processing for images and videos, both
on-demand and on upload, automatic and intelligent responsive breakpoints, and
an HTML widget for direct uploads.

## Installation

```ruby
gem "shrine-cloudinary", "~> 1.1"
```

## Usage

You'll typically want to upload photos directly to Cloudinary, so your setup
might look like this:

```rb
require "cloudinary"
require "shrine/storage/cloudinary"

Cloudinary.config(
  cloud_name: "...",
  api_key:    "...",
  api_secret: "...",
)

Shrine.storages = {
  cache: Shrine::Storage::Cloudinary.new(prefix: "cache"), # for direct uploads
  store: Shrine::Storage::Cloudinary.new,
}
```

### Direct uploads

The `Shrine::Storage::Cloudinary` class implements the `#presign` method, so it
should work with Shrine's [presign_endpoint] plugin and Uppy's [AwsS3] plugin.

If that doesn't work, you can always use Shrine's [upload_endpoint] plugin with
Uppy's [XHRUpload] plugin.

### Copying

If you're using storage as cache where files are accessible over internet,
moving the cached file to Cloudinary storage will not require another upload.
Instead only the file URL will be passed to Cloudinary, then Cloudinary will
internally download it and store the file.

### Images, Videos or Raw

The storage defaults the resource type to "image", but you can change that
by passing the `:resource_type` option:

```rb
Shrine::Storage::Cloudinary.new(resource_type: "video") # "image", "video" or "raw"
```

### Subdirectory

You can choose to store your files in a subdirectory with the `:prefix` option:

```rb
Shrine::Storage::Cloudinary.new(prefix: "uploads")
```

### Controlling access

You can [control access] to uploaded files with the `:type` option:

```rb
Shrine::Storage::Cloudinary.new(type: "private") # upload, private or authenticated
```

### Upload options

If you want some [Cloudinary options] to be applied to all uploads, you can
specify `:upload_options`:

```rb
Shrine::Storage::Cloudinary.new(upload_options: { backup: true })
```

You can also apply upload options dynamically per upload using the
`upload_options` plugin, which is especially useful for doing incoming and
eager transformations:

```rb
class MyUploader < Shrine
  plugin :upload_options, store: ->(io, context) do
    {
      format: "png",
      eager: [
        { width: 500, height: 500, crop: :scale },
        { width: 300, height: 300, crop: :crop, gravity: :south },
      ]
    }
  end
end
```

Finally, you can pass upload options when using the uploader directly:

```rb
uploader.upload(file, upload_options: { format: "png" })
```

### URLs

You can pass transformation options to the URLs:

```rb
user.avatar_url(width: 100, height: 100, crop: :fit) # :crop is mandatory with :width or :height
#=> "https://res.cloudinary.com/myapp/image/upload/w_100,h_100,c_fit/nature.jpg"
```

See [Rails image manipulation] for all URL options you can pass in.

### Metadata

If you decide to do incoming transformations (processing on upload),
shrine-cloudinary will automatically update the extension, size, MIME type,
width and height metadata for the uploaded file.

You can choose to save the whole Cloudinary response to metadata by setting
`:store_data` to true:

```rb
Shrine::Storage::Cloudinary.new(store_data: true, **cloudinary_options)
```
```rb
user = User.create(avatar: image_file)
user.avatar.metadata["cloudinary"] #=>
# {
#   "public_id" => "foo",
#   "version" => 1450294102,
#   "signature" => "379ab45c743951abaea38d6a18ee631af599763f",
#   "width" => 100,
#   "height" => 67,
#   "format" => "jpg",
#   "resource_type" => "image",
#   "created_at" => "2015-12-16T19:28:22Z",
#   "tags" => [],
#   "bytes" => 6147,
#   "type" => "upload",
#   "etag" => "54b5d33d07b1dc4084d7694825371cd7",
#   "url" => "http://res.cloudinary.com/dkjm0biaa/image/upload/v14502\n94102/foo.jpg",
#   "secure_url" => "https://res.cloudinary.com/dkjm0biaa/image/upload/v1450294102/foo.jpg",
#   "original_filename" => "image"
# }
```

## Responsive breakpoints

Cloudinary has a feature for automagically generating [responsive breakpoints]
for images. In Shrine you can leverage this via `:upload_options` and
`:store_data`:

```rb
Shrine::Storage::Cloudinary.new(
  upload_options: { responsive_breakpoints: {...} },
  store_data: true,
)
```

Now each upload will generate responsive breakpoints, and the result will be
saved in the uploaded file's metadata hash under "cloudinary".

```rb
user.avatar.metadata["cloudinary"]["responsive_breakpoints"] #=>
# [{
#   "breakpoints": {
#     {
#       "width": 1000,
#       "height": 667,
#       "bytes": 79821,
#       "url": "http://res.cloudinary.com/demo/image/upload/c_scale,w_1000/v1453637947/dog.jpg",
#       "secure_url": "https://res.cloudinary.com/demo/image/upload/c_scale,w_1000/v1453637947/dog.jpg"
#     },
#     ...
#   }
# }]
```

If the `:responsive_breakpoints` value needs to be dynamic, you can use the
`upload_options` plugin:

```rb
Shrine.plugin :upload_options, store: -> (io, context) do
  { responsive_breakpoints: {...} }
end
```

### Large files

If you're uploading large files with Cloudinary (like videos), you can take
advantage of Cloudinary's special "chunked" upload API, by passing the filesize
threshold after which the special API will be used:

```rb
# Upload files larger than 100 MB using the "chunked" upload API
Shrine::Storage::Cloudinary.new(large: 100*1024*1024)
```

The default chunk size is 20 MB, but you can change that by passing
`:chunk_size` to `:upload_options`:

```rb
Shrine::Storage::Cloudinary.new(
  large: 100*1024*1024                        # 100 MB
  upload_options: { chunk_size: 5*1024*1204 } # 5 MB
)
```

### Updating

Sometimes you may want to apply actions to already uploaded files, e.g.
regenerate tranformations. This storage provides the `#update` method which
delegates to Cloudinary's [explicit API]:

```rb
cloudinary = Shrine::Storage::Cloudinary.new
# ...
cloudinary.update("image.jpg", eager: {...})
```

### Clearing storage

You can delete all files from the Cloudinary storage in the same way as you do
with other storages:

```rb
cloudinary = Shrine::Storage::Cloudinary.new
# ...
cloudinary.clear!
```

## Contributing

Firstly you need to create an `.env` file with Cloudinary credentials:

```sh
# .env
CLOUDINARY_CLOUD_NAME="..."
CLOUDINARY_API_KEY="..."
CLOUDINARY_API_SECRET="..."
```

Afterwards you can run the tests:

```sh
$ bundle exec rake test
```

## Inspiration

This gem has been inspired by Cloudinary's [CarrierWave integration].

## License

[MIT](http://opensource.org/licenses/MIT)

[Cloudinary]: http://cloudinary.com/
[Shrine]: https://github.com/shrinerb/shrine
[CarrierWave integration]: https://github.com/cloudinary/cloudinary_gem
[Cloudinary options]: http://cloudinary.com/documentation/image_upload_api_reference#upload
[Rails image manipulation]: http://cloudinary.com/documentation/rails_image_manipulation
[responsive breakpoints]: http://cloudinary.com/blog/introducing_intelligent_responsive_image_breakpoints_solutions
[explicit API]: http://cloudinary.com/documentation/image_upload_api_reference#explicit
[control access]: http://cloudinary.com/documentation/upload_images#control_access_to_images
[presign_endpoint]: https://github.com/shrinerb/shrine/blob/master/doc/plugins/presign_endpoint.md#readme
[upload_endpoint]: https://github.com/shrinerb/shrine/blob/master/doc/plugins/upload_endpoint.md#readme
[AwsS3]: https://uppy.io/docs/aws-s3/
[XHRUpload]: https://uppy.io/docs/xhr-upload/
