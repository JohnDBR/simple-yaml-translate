# gem install google-cloud-translate-v2

require 'yaml'
require 'google/cloud/translate/v2'
require 'pry'

TRANSLATOR = Google::Cloud::Translate::V2.new(
  key: ''
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
    k[0..-2].each { |x| sub_hash[x] ||= {}; sub_hash = sub_hash[x] }
    sub_hash[k[-1]] = v
  end
end

source = YAML.load_file('input.yml')
source_hash = source.to_hash
flatten_source_hash = flatten_hash(source_hash)

%w[es de fr pt vi zh-CN].each do |language|
  flatten_translated_hash = {}
  flatten_source_hash.each_with_object(flatten_translated_hash) { |(k, v), h| h[k] = TRANSLATOR.translate(v, to: language).text }
  
  unflatten_translated_hash = unflatten_hash(flatten_translated_hash)
  File.open("#{language}_output.yml", 'w+') { |file| file.write(unflatten_translated_hash.to_yaml) }
    
  puts '.'
end
