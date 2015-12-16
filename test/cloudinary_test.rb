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
    @cloudinary.clear!(:confirm)
  end

  it "passes the linter" do
    Shrine::Storage::Linter.new(cloudinary).call(->{image})
  end

  it "passes the linter with prefix" do
    Shrine::Storage::Linter.new(cloudinary(prefix: "prefix")).call(->{image})
  end

  it "passes the linter with resource type" do
    Shrine::Storage::Linter.new(cloudinary(resource_type: "raw")).call(->{image})
  end

  describe "#upload" do
    it "applies upload options" do
      @cloudinary.upload_options.update(width: 50, crop: :fit)
      @cloudinary.upload(image, "foo.jpg", metadata = {})

      assert_equal 50, metadata["width"]
    end

    it "applies additional upload options from metadata" do
      metadata = {"cloudinary" => {width: 50, crop: :fit}}
      @cloudinary.upload(image, "foo.jpg", metadata)

      assert_equal 50, metadata["width"]
    end

    it "can upload remote files" do
      uploaded_file = @uploader.upload(image, location: "foo.jpg")
      @cloudinary.upload(uploaded_file, "bar.jpg")

      assert @cloudinary.exists?("bar.jpg")
    end

    it "can upload other UploadedFiles" do
      uploaded_file = @uploader.upload(image, location: "foo.jpg")
      def @cloudinary.remote?(io) false end
      @cloudinary.upload(uploaded_file, "bar.jpg")

      assert @cloudinary.exists?("bar.jpg")
    end

    it "updates size, mime type and dimensions" do
      @cloudinary.upload(image, "foo.jpg", metadata = {})

      assert_equal image.size, metadata["size"]
      assert_equal "image/jpeg", metadata["mime_type"]
      assert_equal 100, metadata["width"]
      assert_equal 67, metadata["height"]
    end

    it "stores data" do
      @cloudinary = cloudinary(store_data: true)
      @cloudinary.upload(image, "foo.jpg", metadata = {})

      refute_empty metadata["cloudinary"]
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
end
