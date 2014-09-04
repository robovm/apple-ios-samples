#!/usr/bin/ruby

require 'rubygems'
require 'open-uri'
require 'json'
require 'fileutils'
require 'workers'
require 'zip'
require 'nokogiri'
require 'net/https'

$script_name = File.basename($0, File.extname($0))
dest_dir = ARGV[0]
FileUtils.mkdir_p(dest_dir)
dest_dir = File.realpath(dest_dir)

def has_cached(cache_key)
  cache_file = "/tmp/#{$script_name}.tmp/#{cache_key}"
  FileUtils.mkdir_p(File.dirname(cache_file))
  s = File.size?(cache_file)
  s != nil && s > 0
end
def get_cached(cache_key)
  cache_file = "/tmp/#{$script_name}.tmp/#{cache_key}"
  FileUtils.mkdir_p(File.dirname(cache_file))
  s = File.size?(cache_file)
  s != nil && s > 0 ? cache_file : nil
end
def get_url(url, cache_key, &progress_callback)
  cache_file = "/tmp/#{$script_name}.tmp/#{cache_key}"
  FileUtils.mkdir_p(File.dirname(cache_file))
  if !File.size?(cache_file) then
    tmp_file = "#{cache_file}.download"
    f = open(tmp_file, 'wb')
    begin
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.scheme == 'https' ? 443 : 80)
      http.use_ssl = uri.scheme == 'https'
      progress = 0
      http.request_get(uri.path) do |resp|
        resp.read_body do |segment|
          f.write(segment)
          progress = progress + segment.length
          progress_callback.call(progress, resp.content_length) if progress_callback
        end
      end
    ensure
      f.close()
    end
    File.delete(cache_file) if File.size?(cache_file)
    File.rename(tmp_file, cache_file)
  end
  cache_file
end

library = JSON.parse(open(get_url('https://developer.apple.com/library/ios/navigation/library.json', 'library.json')).read)
columns = library['columns']
samples = library['documents'].find_all {|e| e[columns['type']] == 5}
topics = library['topics'].find {|e| e['name'] == 'Topics'}['contents'].inject({}) {|h, e| h[e['key'].to_i] = e['name'].gsub(/&amp;/, '&') ; h}
frameworks = library['topics'].find {|e| e['name'] == 'Frameworks'}['contents'].inject({}) {|h, e| h[e['key'].to_i] = e['name'].gsub(/&amp;/, '&') ; h}

pool = Workers::Pool.new
samples_data = []
lock = Mutex.new
samples.each do |e|
  id = e[columns['id']]
  name = e[columns['name']]
  url = e[columns['url']]
  topic = e[columns['topic']]
  subtopic = e[columns['subtopic']]
  framework = e[columns['framework']]
  # Full URL to sample HTML document
  sample_uri = URI("https://developer.apple.com/library/ios/navigation/").merge(URI(url))
  # Remove fragment
  sample_uri.fragment = nil
  # Get the ../../ dir where the book.json file is located
  sample_base_url = File.dirname(File.dirname(sample_uri.to_s))
  book_url = "#{sample_base_url}/book.json"
  pool.perform do
    begin
      # Download the HTML doc and extract the sample description
      sample_doc = Nokogiri::HTML(open(get_url(sample_uri.to_s, "#{id}.html")))
      description = sample_doc.css('article#contents p').first.content.gsub(/[\n\r]/m, '<br/>')
      # Get the book.json for the sample
      book = JSON.parse(open(get_url("#{sample_base_url}/book.json", id)).read)
      if book['sampleCode']
        zip = book['sampleCode']
        lock.synchronize do
          samples_data.push({:id => id, :name => name, :description => description, :topic => topics[topic], :subtopic => topics[subtopic], :framework => frameworks[framework], :url => sample_uri.to_s, :zip => zip})
        end
        download_url = "#{sample_base_url}/#{zip}"
        if !has_cached(zip)
          printf "%s: Downloading %s\n", name, zip
          archive_file = get_url(download_url, zip) do |progress, content_length|
            # Only output progress for large files
            if progress > 1024 * 1024
              if content_length != nil
                printf "%s: Downloading %s %.2f%%\r", name, zip, (100.0 * progress / content_length)
              else
                printf "%s: Downloading %s %d MB\r", name, zip, progress / 1024 / 1024
              end
            end
          end
          puts "#{name}: Downloaded #{zip} to #{archive_file}"
        end
      end
    rescue Exception => e
      puts "#{name}: Download of #{name} (#{id}) from #{sample_uri} failed :-( (#{e})"
    end
  end
end
pool.shutdown
pool.join

samples_data = samples_data.sort_by {|e| e[:name].upcase}

# Generate a markdown table listing the samples
readme_header = <<-eos
# Mirror of Apple's iOS samples

This repository mirrors [Apple's iOS samples](https://developer.apple.com/library/ios/navigation/#section=Resource%20Types&topic=Sample%20Code).

| Name | Topic | Framework | Description |
| --- | --- | --- | --- |
eos
readme_header.rstrip!
readme = samples_data.map do |e|
  "| [#{e[:name]}](#{e[:url]}) | #{e[:topic]}#{e[:subtopic].empty? ? '' : '<br/>(' + e[:subtopic] + ')'} | #{e[:framework]} | #{e[:description]} |"
end.join("\n")
File.open(File.join(dest_dir, 'README.md'), 'w') {|f| f.write("#{readme_header}\n#{readme}") }

# Extract sample files
samples_data.each do |e|
  zip_file = get_cached(e[:zip])
  puts "Extracting #{zip_file} to #{dest_dir}"
  Zip::File.open(zip_file) do |zip|
    zip.each do |f|
      if !(/(__MACOSX|\.\.)/ =~ f.name)
        f_path = File.join(dest_dir, f.name)
        FileUtils.mkdir_p(File.dirname(f_path))
        puts "    #{f_path}"
        zip.extract(f, f_path)
      end
    end
  end
end
