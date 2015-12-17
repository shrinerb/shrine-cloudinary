# Shrine::Cloudinary

Provides [Cloudinary] storage for [Shrine].

## Installation

```ruby
gem "shrine-cloudinary"
```

## Usage

First you need to configure the Cloudinary gem:

```rb
require "cloudinary"

Cloudinary.config(
  cloud_name: "...",
  api_key:    "...",
  api_secret: "...",
)
```

You can now initialize your storage:

```rb
require "shrine/storage/cloudinary"

Shrine.storages[:store] = Shrine::Storage::Cloudinary.new
```

### Copying

If you're using storage as cache where files are accessible over internet,
moving the cached file to Cloudinary storage will not require another upload.
Instead only the file URL will be passed to Cloudinary, then Cloudinary will
internally download it and store the file.

### Videos and Raw

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

### Upload options

If you want some [Cloudinary options] to be applied to all uploads, you can
specify `:upload_options`:

```rb
Shrine::Storage::Cloudinary.new(upload_options: {type: "authenticated"})
```

### Transformations

Cloudinary allows you to do incoming and eager file transformations, which means
it's possible to trigger file processing on upload. In Shrine you can leverage
that by adding `"cloudinary"` metadata, which you can do by overriding
`Shrine#extract_metadata`:

```rb
class MyUploader < Shrine
  def extract_metadata(io, context)
    super.update("cloudinary" => {
      format: "png",
      eager: [
        {transformation: "small"},
        {transformation: "medium"},
        {transformation: "large"},
      ]
    })
  end
end
```

The above example will trigger named transformations "small", "medium" and
"large", which can be configured in the Cloudinary management console. This
means that you can have different thumbnails of an image, and it's all taken
care of by Cloudinary. When displaying the URL the view, you just need to pass
in the version name to the uploaded file:

```rb
user.avatar_url(transformation: "small")
user.avatar_url(transformation: "medium")
user.avatar_url(transformation: "large")
```

Read [this Cloudinary section](http://cloudinary.com/documentation/rails_image_manipulation)
for all URL options you can pass in.

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
  large: 100*1024*1024                      # 100 MB
  upload_options: {chunk_size: 5*1024*1204} # 5 MB
)
```

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

If you're using the storage directly, `Shrine::Storage::Cloudinary#upload` will
return this hash.

### Clearing storage

You can delete all files from the Cloudinary storage in the same way as you do
with other storages:

```rb
cloudinary = Shrine::Storage::Cloudinary.new
# ...
cloudinary.clear!(:confirm)
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

## License

[MIT](http://opensource.org/licenses/MIT)

[Cloudinary]: http://cloudinary.com/
[Shrine]: https://github.com/janko-m/shrine
[Cloudinary options]: http://cloudinary.com/documentation/upload_images#remote_upload
