Hydra::Derivatives.ffmpeg_path = YAML.load_file(Rails.root.join('config', 'hydra_derivatives.yml'))[Rails.env]['ffmpeg_path']
Hydra::Derivatives.fits_path =  YAML.load_file(Rails.root.join('config', 'hydra_derivatives.yml'))[Rails.env]['fits_path']
Hydra::Derivatives.libreoffice_path =  YAML.load_file(Rails.root.join('config', 'hydra_derivatives.yml'))[Rails.env]['libreoffice_path']
Hydra::Derivatives.kdu_compress_path =  YAML.load_file(Rails.root.join('config', 'hydra_derivatives.yml'))[Rails.env]['kdu_compress_path']
Hydra::Derivatives.kdu_compress_recipes = YAML.load_file(Rails.root.join('config', 'hydra_derivatives.yml'))[Rails.env]['jp2_recipes']

#FIXME
ARK_CONFIG_GLOBAL = YAML.load_file(Rails.root.join('config', 'ark.yml'))["development"]