require 'rubygems'
require 'bundler/setup'
require 'sinatra/base'
require 'rack/deflater'
require 'pathname'

class App < Sinatra::Base
  CONTENT_TYPE = 'text/plain'.freeze
  TEXT_HEADERS = {
    'Access-Control-Allow-Origin'.freeze => '*'.freeze,
    'Content-Type'.freeze => CONTENT_TYPE
  }.freeze
  PATH = Pathname.new(__FILE__).join('../generated'.freeze).freeze
  STATUS = 'alive'.freeze

  def app_path tag
    PATH.join(tag)
  end

  def generated_apps
    PATH.children.map(&:basename)
  end

  def known_versions
    generated_apps.map { |name| Gem::Version.new(name.to_s[1..-1]) }.sort
  end

  before do
    halt 406, TEXT_HEADERS, '' unless request.accept?(CONTENT_TYPE)
  end

  get '/status' do
    return 200, TEXT_HEADERS, STATUS
  end

  get '/versions' do
    return 200, TEXT_HEADERS, known_versions.join("\n")
  end

  get %r{/(v[^/]+)/(v.+)} do |source, target|
    source_path = app_path(source)
    target_path = app_path(target)

    if source_path.exist?  && target_path.exist?
      diff = `diff -Nr -U 1000 -x '*.png' #{source_path} #{target_path}`
      return 200, TEXT_HEADERS, diff
    else
      halt 404, TEXT_HEADERS, ''
    end
  end

  not_found do
    halt 404, TEXT_HEADERS, ''
  end
end

use Rack::Deflater
run App
