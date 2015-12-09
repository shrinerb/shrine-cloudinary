Gem::Specification.new do |gem|
  gem.name          = "shrine-cloudinary"
  gem.version       = "0.1.0"

  gem.required_ruby_version = ">= 2.1"

  gem.summary      = "Provides Cloudinary storage for Shrine."
  gem.homepage     = "https://github.com/janko-m/shrine-cloudinary"
  gem.authors      = ["Janko Marohnić"]
  gem.email        = ["janko.marohnic@gmail.com"]
  gem.license      = "MIT"

  gem.files        = Dir["README.md", "LICENSE.txt", "lib/**/*.rb", "shrine-cloudinary.gemspec"]
  gem.require_path = "lib"

  gem.add_dependency "cloudinary"
  gem.add_dependency "down", ">= 1.0.3"

  gem.add_development_dependency "rake"
  gem.add_development_dependency "shrine"
  gem.add_development_dependency "minitest"
  gem.add_development_dependency "dotenv"
end
