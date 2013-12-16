# Load the
APP_CONFIG = YAML.load(File.read(File.expand_path('../../application.yml', __FILE__)))
APP_CONFIG.merge! APP_CONFIG.fetch(Rails.env, {})
APP_CONFIG.deep_symbolize_keys!



# Custom Configuration Loading Here
UMBC_CONFIG = YAML.load(File.read(File.expand_path('../../umbc.yml', __FILE__)))
UMBC_CONFIG.merge! UMBC_CONFIG.fetch(Rails.env, {})
UMBC_CONFIG.deep_symbolize_keys!