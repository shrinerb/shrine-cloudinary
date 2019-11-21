Gem::Specification.new do |gem|
  gem.name          = "shrine-cloudinary"
  gem.version       = "1.1.1"

  gem.required_ruby_version = ">= 2.1"

  gem.summary      = "Provides Cloudinary storage for Shrine."
  gem.homepage     = "https://github.com/shrinerb/shrine-cloudinary"
  gem.authors      = ["Janko Marohnić"]
  gem.email        = ["janko.marohnic@gmail.com"]
  gem.license      = "MIT"

  gem.files        = Dir["README.md", "LICENSE.txt", "lib/**/*.rb", "*.gemspec"]
  gem.require_path = "lib"

  gem.add_dependency "shrine", ">= 3.0.0.rc", "< 4"
  gem.add_dependency "cloudinary", "~> 1.12"
  gem.add_dependency "down", "~> 5.0"
  gem.add_dependency "http", ">= 3.2", "< 5"

  gem.add_development_dependency "rake"
  gem.add_development_dependency "minitest"
  gem.add_development_dependency "dotenv"
end
