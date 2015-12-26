Gem::Specification.new do |gem|
  gem.name          = "shrine-cloudinary"
  gem.version       = "0.2.1"

  gem.required_ruby_version = ">= 2.1"

  gem.summary      = "Provides Cloudinary storage for Shrine."
  gem.homepage     = "https://github.com/janko-m/shrine-cloudinary"
  gem.authors      = ["Janko Marohnić"]
  gem.email        = ["janko.marohnic@gmail.com"]
  gem.license      = "MIT"

  gem.files        = Dir["README.md", "LICENSE.txt", "lib/**/*.rb", "shrine-cloudinary.gemspec"]
  gem.require_path = "lib"

  gem.add_dependency "shrine", "~> 1.1"
  gem.add_dependency "cloudinary"
  gem.add_dependency "down", ">= 1.0.5"

  gem.add_development_dependency "rake"
  gem.add_development_dependency "minitest"
  gem.add_development_dependency "dotenv"
end
