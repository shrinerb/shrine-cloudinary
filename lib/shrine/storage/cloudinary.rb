require "shrine"
require "cloudinary"
require "down/http"

class Shrine
  module Storage
    class Cloudinary
      attr_reader :prefix, :resource_type, :type, :upload_options

      def initialize(prefix: nil, resource_type: "image", type: "upload", store_data: nil, upload_options: {}, large: nil)
        @prefix = prefix
        @large = large
        @resource_type = resource_type
        @type = type
        @upload_options = upload_options
        @store_data = store_data
      end

      def upload(io, id, shrine_metadata: {}, **upload_options)
        options = { public_id: public_id(id) }
        options.update(default_options)
        options.update(@upload_options)
        options.update(upload_options)

        result = store(io, **options)

        update_id!(result, id)
        update_metadata!(result, shrine_metadata)

        result
      end

      def update(id, **options)
        ::Cloudinary::Uploader.explicit(public_id(id), default_options.merge(options))
      end

      def move(io, id, shrine_metadata: {}, **upload_options)
        ::Cloudinary::Uploader.rename(io.storage.public_id(io.id), public_id(id), default_options)
      end

      def movable?(io, id)
        io.is_a?(UploadedFile) && io.storage.is_a?(Storage::Cloudinary)
      end

      def open(id, **options)
        Down::Http.open(url(id), **options)
      end

      def exists?(id)
        result = ::Cloudinary::Api.resources_by_ids([public_id(id)], default_options)
        result.fetch("resources").any?
      end

      def delete(id)
        ::Cloudinary::Uploader.destroy(public_id(id), default_options)
      end

      def url(id, **options)
        ::Cloudinary::Utils.cloudinary_url(path(id), default_options.merge(secure: true, **options))
      end

      def clear!(**options)
        if prefix
          ::Cloudinary::Api.delete_resources_by_prefix(prefix, default_options.merge(options))
        else
          ::Cloudinary::Api.delete_all_resources(default_options.merge(options))
        end
      end

      def presign(id = nil, **options)
        upload_options = id ? { public_id: public_id(id) } : { folder: prefix }
        upload_options.update(@upload_options)

        fields = ::Cloudinary::Uploader.build_upload_params(upload_options.merge(options))
        fields.reject! { |key, value| value.nil? || value == "" }
        fields[:signature] = ::Cloudinary::Utils.api_sign_request(fields, ::Cloudinary.config.api_secret)
        fields[:api_key] = ::Cloudinary.config.api_key

        url = ::Cloudinary::Utils.cloudinary_api_url("upload", default_options)

        { method: :post, url: url, fields: fields }
      end

      protected

      def public_id(id)
        if resource_type == "raw"
          path(id)
        else
          path(id).chomp(File.extname(id))
        end
      end

      def path(id)
        [*prefix, id].join("/")
      end

      private

      def store(io, chunk_size: nil, **options)
        if remote?(io)
          ::Cloudinary::Uploader.upload(io.url, **options)
        else
          make_rest_client_recognize_as_file!(io)
          if large?(io)
            io.instance_eval { def match(*); false; end } # https://github.com/cloudinary/cloudinary_gem/pull/260
            ::Cloudinary::Uploader.upload_large(io, chunk_size: chunk_size, **options)
          else
            ::Cloudinary::Uploader.upload(io, **options)
          end
        end
      end

      def remote?(io)
        io.is_a?(UploadedFile) && io.url.to_s =~ /^ftp:|^https?:/
      end

      def large?(io)
        io.size >= @large if @large
      end

      def default_options
        { resource_type: resource_type, type: type }
      end

      def make_rest_client_recognize_as_file!(io)
        io.instance_eval { def path; "file"; end } unless io.respond_to?(:path)
        io.instance_eval { def original_filename; "file"; end } if io.respond_to?(:original_filename)
      end

      def update_id!(result, id)
        uploaded_id  = result.fetch("public_id")
        uploaded_id  = uploaded_id.match("#{prefix}/").post_match if prefix
        uploaded_id += ".#{result["format"]}" if result["format"]

        id.replace(uploaded_id)
      end

      def update_metadata!(result, metadata)
        retrieved_metadata = {
          "size"      => result["bytes"],
          "mime_type" => MIME_TYPES[result["format"]],
          "width"     => result["width"],
          "height"    => result["height"],
        }
        retrieved_metadata["cloudinary"] = result if @store_data
        retrieved_metadata.reject! { |key, value| value.nil? }

        metadata.update(retrieved_metadata)
      end

      MIME_TYPES = {
        # Images
        "jpg"  => "image/jpeg",
        "png"  => "image/png",
        "gif"  => "image/gif",
        "bmp"  => "image/bmp",
        "tiff" => "image/tiff",
        "ico"  => "image/x-icon",
        "pdf"  => "application/pdf",
        "eps"  => "application/postscript",
        "psd"  => "application/octet-stream",
        "svg"  => "image/svg+xml",
        "webp" => "image/webp",

        # Videos
        "mp4"  => "video/mp4",
        "flv"  => "video/x-flv",
        "mov"  => "video/quicktime",
        "ogv"  => "video/ogg",
        "webm" => "video/webm",
        "3gp"  => "video/3gpp",
        "3g2"  => "video/3gpp2",
        "wmv"  => "video/x-ms-wmv",
        "mpeg" => "video/mpeg",
        "avi"  => "video/x-msvideo",
      }
    end
  end
end
