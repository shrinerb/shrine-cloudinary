require "shrine"
require "cloudinary"
require "down"

class Shrine
  module Storage
    class Cloudinary
      attr_reader :prefix, :resource_type, :upload_options

      def initialize(prefix: nil, large: nil, resource_type: "image", store_data: nil, upload_options: {})
        @prefix = prefix
        @large = large
        @resource_type = resource_type
        @upload_options = upload_options.merge(resource_type: resource_type)
        @store_data = store_data
      end

      def upload(io, id, shrine_metadata: {}, **upload_options)
        options = {public_id: public_id(id)}
        options.update(@upload_options)
        options.update(upload_options)

        result = store(io, **options)

        update_id!(result, id)
        update_metadata!(result, shrine_metadata)

        result
      end

      def download(id)
        Down.download(url(id))
      end

      def update(id, **options)
        options = {resource_type: resource_type, type: type}.merge(options)
        ::Cloudinary::Uploader.explicit(public_id(id), **options)
      end

      def move(io, id, shrine_metadata: {}, **upload_options)
        options = {resource_type: resource_type}
        ::Cloudinary::Uploader.rename(io.storage.public_id(io.id), public_id(id), **options)
      end

      def movable?(io, id)
        io.is_a?(UploadedFile) && io.storage.is_a?(Storage::Cloudinary)
      end

      def open(id)
        download(id)
      end

      def read(id)
        ::Cloudinary::Downloader.download(url(id))
      end

      def exists?(id)
        options = {resource_type: resource_type}
        result = ::Cloudinary::Api.resources_by_ids([public_id(id)], **options)
        result.fetch("resources").any?
      end

      def delete(id)
        options = {resource_type: resource_type}
        ::Cloudinary::Uploader.destroy(public_id(id), **options)
      end

      def multi_delete(ids)
        public_ids = ids.map { |id| public_id(id) }
        options = {resource_type: resource_type}
        ::Cloudinary::Api.delete_resources(public_ids, **options)
      end

      def url(id, **options)
        options = {resource_type: resource_type, type: type}.merge(options)
        ::Cloudinary::Utils.cloudinary_url(path(id), **options)
      end

      def clear!(**options)
        options = {resource_type: resource_type}.merge(options)
        if prefix
          ::Cloudinary::Api.delete_resources_by_prefix(prefix, **options)
        else
          ::Cloudinary::Api.delete_all_resources(**options)
        end
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
          io = io.download if io.is_a?(UploadedFile)
          if large?(io)
            ::Cloudinary::Uploader.upload_large(io, chunk_size: chunk_size, **options)
          else
            ::Cloudinary::Uploader.upload(io, **options)
          end
        end
      end

      def type
        upload_options[:type] || "upload"
      end

      def remote?(io)
        io.is_a?(UploadedFile) && io.url.to_s =~ /^ftp:|^https?:/
      end

      def large?(io)
        io.size >= @large if @large
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
