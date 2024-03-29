# frozen_string_literal: true

require 'dotenv'
require 'yaml'
require 'google/cloud/translate/v2'
require 'pry'

Dotenv.load

TRANSLATOR = Google::Cloud::Translate::V2.new(
  key: ENV['GOOGLE']
)

def flatten_hash(hash)
  hash.each_with_object({}) do |(k, v), h|
    if v.is_a? Hash
      flatten_hash(v).map { |h_k, h_v| h["#{k}.#{h_k}".to_sym] = h_v }
    else
      h[k] = v
    end
  end
end

def unflatten_hash(hash)
  hash.transform_keys! { |tk| tk.to_s.split('.') }
  hash.each_with_object({}) do |(k, v), h|
    sub_hash = h
    k[0..-2].each do |x|
      sub_hash[x] ||= {}
      sub_hash = sub_hash[x]
    end
    sub_hash[k[-1]] = v
  end
end

errors = {}
source = YAML.load_file('./input.yml')
source_hash = source.to_hash
flatten_source_hash = flatten_hash(source_hash)

puts 'SIMPLE YAML TRANSLATION HAS STARTED!'

%w[es de fr pt vi zh-CN th].each do |language|
  failure = false
  flatten_translated_hash = {}

  flatten_source_hash.each_with_object(flatten_translated_hash) do |(k, v), h|
    print '.'
    h[k] = TRANSLATOR.translate(v, to: language, format: 'text').text
  rescue StandardError => _e
    failure = true
    errors[language] ||= {}
    errors[language][k] ||= v 
    
    h[k] = 'FAILURE!'
  end
  print "\n"

  unflatten_translated_hash = unflatten_hash(flatten_translated_hash)
  File.open("translated/#{language}_output.yml", 'w+') { |file| file.write(unflatten_translated_hash.to_yaml) }

  if failure
    puts " ---- Language: #{language} translate failed" 
  else
    puts " ---- Language: #{language} translate successful"
  end
end

puts 'Errors ->'
pp errors
