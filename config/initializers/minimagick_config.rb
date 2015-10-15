MiniMagick.configure do |config|
  config.cli = :imagemagick
  #config.timeout = 2000
  config.timeout = 10000
  config.shell_api = "posix-spawn"
  config.whiny = false
end