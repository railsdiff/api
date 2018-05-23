require 'rubygems'
require 'bundler/setup'
require 'sinatra/base'
require 'rack/cache'
require 'rack/cache/key'
require 'rack/deflater'
require 'pathname'

class QuerylessCacheKey < Rack::Cache::Key
  private

  # Internal: This API does not consider query string parameters, so ignore
  # them when generating cache keys.
  #
  def query_string
    nil
  end
end

class App < Sinatra::Base
  CONTENT_TYPE = 'text/plain'.freeze
  HEADERS = {
    'Access-Control-Allow-Origin'.freeze => '*'.freeze,
    'Content-Type'.freeze => "#{CONTENT_TYPE}; charset=utf-8".freeze
  }.freeze
  CACHEABLE_HEADERS = HEADERS.merge({
    'Cache-Control'.freeze => 'public, max-age=31536000'.freeze
  })
  PATH = Pathname.new(__FILE__).join('../generated'.freeze).freeze
  STATUS = 'alive'.freeze

  def app_path(*tag)
    PATH.join(*tag)
  end

  def generated_apps
    PATH.children.map(&:basename)
  end

  def known_versions
    generated_apps.map { |name| Gem::Version.new(name.to_s[1..-1]) }.sort
  end

  before do
    halt 406, HEADERS, '' unless request.accept?(CONTENT_TYPE)
  end

  get '/status' do
    return 200, HEADERS, STATUS
  end

  get '/versions' do
    return 200, HEADERS, known_versions.join("\n")
  end

  get %r{/(v[^/]+)/(v[^/]+)(?:/(.+))?} do |source, target, path|
    file_path = path || ''

    source_app_path = app_path(source)
    source_path = app_path(source, file_path)

    target_app_path = app_path(target)
    target_path = app_path(target, file_path)

    if source_app_path.exist? && target_app_path.exist? && source_path.exist? || target_path.exist?
      diff = `diff -Nr -U 1000 -x '*.png' #{source_path} #{target_path}`
      return 200, CACHEABLE_HEADERS, diff
    else
      halt 404, HEADERS, ''
    end
  end

  not_found do
    halt 404, HEADERS, ''
  end
end

use Rack::Cache, { :cache_key => QuerylessCacheKey }
use Rack::Deflater
run App
