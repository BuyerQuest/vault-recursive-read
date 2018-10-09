#!/usr/bin/env ruby
# rubocop:disable Metrics/LineLength,Metrics/MethodLength,Metrics/AbcSize

require 'yaml'
require 'json'
require 'vault'
require 'optparse'

APP_TITLE = 'Vault recursive read'.freeze
SCRIPT_NAME = __FILE__.freeze
VERSION = '1.0.0'.freeze

options = {}
parser = OptionParser.new do |opts|
  opts.banner = "Recursive read for paths in vault.\n\nUsage: #{SCRIPT_NAME} [options]"

  opts.on('-pPATH', '--path=PATH', 'Path in vault to read from, with a trailing slash. E.g. secret/foo/') do |v|
    options[:path] = v
  end

  opts.separator('')
  opts.on('-aVAULT_ADDR', '--vault-address=VAULT_ADDR', 'Optional: URL used to access the Vault server. Defaults to the VAULT_ADDR environment variable') do |v|
    options[:vault_addr] = v
  end

  opts.on('-tVAULT_TOKEN', '--vault-token=VAULT_TOKEN', 'Optional: A vault token. Defaults to VAULT_TOKEN environment variable, or reads ~/.vault-token') do |v|
    options[:vault_token] = v
  end

  opts.on('-fFORMAT', '--format=FORMAT', 'Optional: Output data format. Supports YAML & JSON. Defaults to YAML') do |v|
    options[:format] = v
  end

  opts.separator('')
  opts.on('-h', '--help', 'Display this help') do
    puts opts
    exit
  end

  opts.on('-v', '--version', 'Display the current script version') do
    puts "#{APP_TITLE} - version #{VERSION}"
    exit
  end
end
parser.parse!

# Check for a path
raise OptionParser::MissingArgument, 'PATH is required. Try the --help argument.' if options[:path].nil?

vault_url = options[:vault_addr].nil? ? ENV['VAULT_ADDR'] : options[:vault_addr]

# Check that we have something for the vault URL
raise OptionParser::MissingArgument, 'Vault Address is required' if vault_url.nil?

# Set the output format
output_format = options[:format].nil? ? 'yaml' : options[:format].downcase

# Uncover the full path of every subkey under a given vault key
def get_vault_paths(keys = 'secret/')
  # We need to work with an array
  if keys.is_a?(String)
    keys = [keys]
  else
    raise ArgumentError, 'The supplied path must be a string or an array of strings.' unless keys.is_a?(Array)
  end

  # the first element should have a slash on the end, otherwise
  # this function is likely being called improperly
  keys.each do |key|
    raise ArgumentError, "The supplied path #{key} should end in a slash." unless key[-1] == '/'
  end

  # go through each key and add all sub-keys to the array
  keys.each do |key|
    Vault.logical.list(key).each do |subkey|
      # if the key has a slash on the end, we must go deeper
      keys.push("#{key}#{subkey}") if subkey[-1] == '/'
    end
  end

  # Remove duplicates (probably unnecessary), and sort
  keys.uniq.sort
end

# Find all of the secrets sitting under an array of vault paths
def get_vault_secret_keys(vault_paths)
  if vault_paths.is_a?(String)
    vault_paths = [vault_paths]
  else
    raise ArgumentError, 'The supplied path must be a string or an array of strings.' unless vault_paths.is_a?(Array)
  end

  vault_secrets = []

  vault_paths.each do |key|
    Vault.logical.list(key).each do |secret|
      vault_secrets.push("#{key}#{secret}") unless secret[-1] == '/'
    end
  end

  # return a sorted array
  vault_secrets.sort
end

# Check that we have a vault token we can use
token = options[:vault_token].nil? ? ENV['VAULT_TOKEN'] : options[:vault_token]

# Pull from the home directory if we don't have it in our environment
if token.nil?
  begin
    token = File.read("#{Dir.home}/.vault-token")
  rescue Errno::ENOENT => e
    raise Errno::ENOENT, "Missing vault token file: #{e}"
  end
end

# Sanity check the token
raise 'Your vault token is blank for some reason. Authenticate with vault first.' if token.nil? || token == ''

# Configure the Vault gem
Vault.configure do |vault|
  vault.address = vault_url
  vault.token = token
  vault.ssl_verify = false
end

# Read the secrets
secrets = {}

get_vault_paths(options[:path]).each do |path|
  get_vault_secret_keys(path).each do |key|
    secret = Vault.logical.read(key)
    if secret.respond_to? :data
      STDERR.puts "Reading #{key}"
      secrets[key] = secret.data
    else
      STDERR.puts "Skipped #{key} (no data)"
    end
  end
end

# Output
case output_format
when 'json'
  puts secrets.to_json
else
  puts secrets.to_yaml
end
