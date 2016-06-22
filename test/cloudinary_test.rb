require "test_helper"
require "shrine/storage/linter"

describe Shrine::Storage::Cloudinary do
  def cloudinary(options = {})
    Shrine::Storage::Cloudinary.new(options)
  end

  before do
    @cloudinary = cloudinary
    uploader_class = Class.new(Shrine)
    uploader_class.storages[:cloudinary] = @cloudinary
    @uploader = uploader_class.new(:cloudinary)
  end

  after do
    @cloudinary.clear!
  end

  it "passes the linter" do
    Shrine::Storage::Linter.new(cloudinary).call(->{image})
  end

  it "passes the linter with :prefix" do
    Shrine::Storage::Linter.new(cloudinary(prefix: "prefix")).call(->{image})
  end

  it "passes the linter with :resource_type" do
    Shrine::Storage::Linter.new(cloudinary(resource_type: "raw")).call(->{image})
  end

  describe "#upload" do
    it "applies upload options" do
      @cloudinary.upload_options.update(width: 50, crop: :fit)
      uploaded_file = @uploader.upload(image)

      assert_equal 50, uploaded_file.metadata["width"]
    end

    it "applies additional upload options from metadata" do
      @uploader.class.plugin :upload_options, cloudinary: {width: 50, crop: :fit}
      uploaded_file = @uploader.upload(image)

      assert_equal 50, uploaded_file.metadata["width"]
    end

    it "can upload remote files" do
      uploaded_file = @uploader.upload(image)
      @cloudinary.upload(uploaded_file, "bar.jpg")

      assert @cloudinary.exists?("bar.jpg")
    end

    it "can upload other UploadedFiles" do
      uploaded_file = @uploader.upload(image)
      def @cloudinary.remote?(io) false end
      @cloudinary.upload(uploaded_file, "bar.jpg")

      assert @cloudinary.exists?("bar.jpg")
    end

    it "updates size, mime type and dimensions" do
      uploaded_file = @uploader.upload(image)
      uploaded_file.metadata.clear
      uploaded_file = @uploader.upload(uploaded_file)

      assert_equal image.size, uploaded_file.metadata["size"]
      assert_equal "image/jpeg", uploaded_file.metadata["mime_type"]
      assert_equal 100, uploaded_file.metadata["width"]
      assert_equal 67, uploaded_file.metadata["height"]
    end

    it "stores data" do
      @cloudinary.instance_variable_set("@store_data", true)
      uploaded_file = @uploader.upload(image)

      refute_empty uploaded_file.metadata["cloudinary"]
    end

    it "updates the id with the actual extension" do
      @cloudinary.upload(image, id = "foo.mp4")
      assert_equal "foo.jpg", id

      @cloudinary.upload(image, id = "foo")
      assert_equal "foo.jpg", id
    end

    it "uploads large files" do
      @cloudinary = cloudinary(large: 1)
      @cloudinary.upload(image, "foo.jpg")

      assert @cloudinary.exists?("foo.jpg")
    end

    it "returns the data for the uploaded file" do
      result = @cloudinary.upload(image, "foo.jpg")

      assert_equal "foo", result["public_id"]
    end
  end

  describe "#update" do
    it "updates the data of the file" do
      @cloudinary.upload(image, id = "foo.jpg")
      response = @cloudinary.update(id, tags: "foo,bar")

      assert_equal ["foo", "bar"], response["tags"]
    end
  end

  describe "#url" do
    it "returns the URL with an extension" do
      assert_includes @cloudinary.url("foo.jpg"), "foo.jpg"
    end

    it "accepts additional options" do
      url = @cloudinary.url("foo.jpg", crop: :fit, width: 150, height: 150)

      assert_includes url, "c_fit"
      assert_includes url, "h_150"
      assert_includes url, "w_150"
    end

    it "respects resource type" do
      cloudinary = cloudinary(resource_type: "video")

      assert_includes cloudinary.url("foo.mp4"), "video"
    end
  end

  describe "#presign" do
    it "returns information necessary for direct uploads" do
      @cloudinary = cloudinary(prefix: "cache")
      presign = @cloudinary.presign(id = "image.jpg")

      file = image.tap { |o| o.instance_eval { def path; "file"; end } }
      RestClient.post(presign.url, file: file, **presign.fields)

      assert @cloudinary.exists?(id)
    end

    it "doesn't require the id" do
      @cloudinary = cloudinary(prefix: "cache")
      presign = @cloudinary.presign

      file = image.tap { |o| o.instance_eval { def path; "file"; end } }
      response = RestClient.post(presign.url, file: file, **presign.fields)
      response = JSON.parse(response)
      id = "#{response["public_id"]}.#{response["format"]}"[/cache\/(.+)/, 1]

      assert @cloudinary.exists?(id)
    end
  end
end
