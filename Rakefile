require 'json'

VERBOSE = ENV.key?('VERBOSE')

task 'default' => 'generate'

desc 'Generate diff, json, & sitemap files'
task 'generate' => 'update_rails_repo' do |t|
  all_included_tags.each do |tag|
    Rake::Task["generated/#{tag}"].invoke
  end
end

desc 'List all tags'
task 'tags' => 'update_rails_repo' do |t|
  puts all_included_tags.to_a
end

directory 'tmp/rails'

file 'tmp/rails/rails' => 'tmp/rails' do |t|
  puts 'Cloning Rails repo'
  sh "git clone https://github.com/rails/rails.git #{t.name} > /dev/null 2>&1", verbose: VERBOSE
end

task 'update_rails_repo' => 'tmp/rails/rails' do |t|
  puts 'Updating Rails repo'

  cd t.prerequisites.first, verbose: VERBOSE do
    sh "git fetch origin --tags > /dev/null", verbose: VERBOSE
  end
end

file 'tmp/rails/generator' => 'tmp/rails' do |t|
  generator = <<-GEN
activesupport_path = File.expand_path('../activesupport/lib', __FILE__)
railties_path = File.expand_path('../railties/lib', __FILE__)
$:.unshift(activesupport_path)
$:.unshift(railties_path)
require "rails/cli"
  GEN
  File.write(t.name, generator)
end

rule(%r{tmp/rails/.*} => ['tmp/rails/rails', 'tmp/rails/generator']) do |t|
  cd t.source, verbose: VERBOSE do
    tag = t.name.pathmap('%f')
    sh "git reset --hard #{tag} > /dev/null 2>&1", verbose: VERBOSE
  end
  cp_r t.source, t.name, verbose: VERBOSE
  cp 'tmp/rails/generator', t.name, verbose: VERBOSE
end

directory 'generated'

rule(%r{generated/.*} => ['generated']) do |t|
  source = t.name.pathmap('%{generated,tmp/rails}p')
  Rake::Task[source].invoke # only invoke this task if we need generated app

  puts 'Generating: %s' % t.name

  rm_rf t.name, verbose: VERBOSE if Dir.exists?(t.name)
  sh generator_command(source, t.name), verbose: VERBOSE
  sed_commands(t.name).each do |expression, file_path|
    sh %{sed -E -i '' "#{expression}" #{file_path}}, verbose: VERBOSE
  end
  %x{test -d "#{t.name}/railsdiff/.git" && rm -rf "#{t.name}/railsdiff/.git"}
  sh "mv #{t.name}/railsdiff/* #{t.name}/.", verbose: VERBOSE

  hidden_glob = "#{t.name}/railsdiff/.??*"
  %x{test -n "$(ls #{hidden_glob})" && mv #{hidden_glob} #{t.name}/.}

  rm_rf source, verbose: VERBOSE
end

def all_included_tags
  @all_included_tags ||= all_tags.select { |tag| include_version?(version(tag)) }
end

def all_tags
  @all_tags ||= begin
    result = nil
    cd 'tmp/rails/rails', verbose: VERBOSE do
      result = %x{git tag -l "v[!0-2]*" "v2.3*"}.split
    end
    result.sort { |a, b| version(a) <=> version(b) }
  end
end

def generator_command source_path, dest_path
  if source_path.split(/\//).last =~ /v2.3/
    "ruby #{source_path}/railties/bin/rails #{dest_path}/railsdiff > /dev/null"
  else
    "ruby #{source_path}/generator new #{dest_path}/railsdiff --skip-bundle --skip-webpack-install > /dev/null"
  end
end

def include_version? version
  (!version.prerelease? || version >= min_prerelease_version) &&
    version >= min_version && !skip_version?(version)
end

def min_prerelease_version
  @min_prerelease_version ||= version 'v3.1.0.beta1'
end

def min_version
  @min_version ||= version 'v2.3.6'
end

def sed_commands base_path
  [
    [
      "s/.*/your-encrypted-credentials/",
      "#{base_path}/railsdiff/config/credentials.yml.enc",
    ],
    [
      "s/'.*'/'your-secret-token'/",
      "#{base_path}/railsdiff/config/initializers/cookie_verification_secret.rb",
    ],
    [
      "s/'.*'/'your-secret-token'/",
      "#{base_path}/railsdiff/config/initializers/secret_token.rb",
    ],
    [
      "s/'.{20,}'/'your-secret-token'/",
      "#{base_path}/railsdiff/config/initializers/session_store.rb",
    ],
    [
      's/(secret_key_base:[[:space:]])[^<].*$/\1your-secret-token/',
      "#{base_path}/railsdiff/config/secrets.yml",
    ],
  ].select { |_expression, file_path| File.exists?(file_path) }
end

def skip_version? version
  %w[2.3.9.pre 2.3.2.1 2.3.3.1].include?(version.to_s) ||
    version.to_s.include?('github')
end

def version tag
  Gem::Version.new(tag[1..-1])
rescue
  Gem::Version.new('0')
end
