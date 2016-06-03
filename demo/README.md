# Shrine & Cloudinary Demo

This is a Roda & Sequel demo app for integrating Cloudinary file uploads with
Shrine.

## Requirements

You need to have the following:

* SQLite
* Cloudinary account
* [Upload preset] for unsigned uploads

## Setup

* Add .env with Cloudinary credentials:

  ```sh
  # .env
  CLOUDINARY_CLOUD_NAME="..."
  CLOUDINARY_PRESET_NAME="..."
  CLOUDINARY_API_KEY="..."
  CLOUDINARY_API_SECRET="..."
  ```

* Run `bundle install`

* Run `rake db:migrate`

* Run `bundle exec rackup`

[Upload preset]: https://cloudinary.com/console/settings/upload
