MiniMagick.configure do |config|
  config.cli = :imagemagick
  config.timeout = 2000
  config.whiny = false
end