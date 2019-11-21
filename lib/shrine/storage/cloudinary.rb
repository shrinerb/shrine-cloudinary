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
        options.merge!(@upload_options)
        options.merge!(upload_options)

        result = store(io, **options)

        update_id!(result, id)
        update_metadata!(result, shrine_metadata)

        result
      end

      def update(id, **options)
        uploader.explicit(public_id(id), **options)
      end

      def open(id, **options)
        Down::Http.open(url(id, sign_url: true), **options)
      rescue Down::NotFound
        raise Shrine::FileNotFound, "file #{id.inspect} not found on storage"
      end

      def exists?(id)
        result = api.resources_by_ids([public_id(id)])
        result.fetch("resources").any?
      end

      def delete(id)
        uploader.destroy(public_id(id))
      end

      def url(id, **options)
        utils.cloudinary_url(path(id), secure: true, **options)
      end

      def clear!(**options)
        if prefix
          api.delete_resources_by_prefix(prefix, **options)
        else
          api.delete_all_resources(**options)
        end
      end

      def presign(id = nil, **presign_options)
        options = id ? { public_id: public_id(id) } : { folder: prefix }
        options.merge!(@upload_options)
        options.merge!(presign_options)

        fields = ::Cloudinary::Uploader.build_upload_params(options)
        fields.reject! { |key, value| value.nil? || value == "" }
        fields[:signature] = ::Cloudinary::Utils.api_sign_request(fields, ::Cloudinary.config.api_secret)
        fields[:api_key]   = ::Cloudinary.config.api_key

        url = utils.cloudinary_api_url("upload")

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
          uploader.upload(io.url, **options)
        else
          Shrine.with_file(io) do |file|
            if large?(file)
              uploader.upload_large(file, chunk_size: chunk_size, **options)
            else
              uploader.upload(file, **options)
            end
          end
        end
      end

      def uploader; Delegator.new(::Cloudinary::Uploader, default_options); end
      def api;      Delegator.new(::Cloudinary::Api,      default_options); end
      def utils;    Delegator.new(::Cloudinary::Utils,    default_options); end

      def remote?(io)
        io.is_a?(UploadedFile) && io.url.to_s =~ /^ftp:|^https?:/
      end

      def large?(io)
        io.size >= @large if @large
      end

      def default_options
        { resource_type: resource_type, type: type }
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

      # Delegates each method call to the specified klass, but passing
      # specified default options.
      class Delegator
        def initialize(klass, default_options)
          @klass           = klass
          @default_options = default_options
        end

        def method_missing(name, *args, **options, &block)
          @klass.public_send(name, *args, **@default_options, **options, &block)
        end

        def respond_to_missing?(name, include_private = false)
          @klass.respond_to?(name, include_private)
        end
      end
    end
  end
end
