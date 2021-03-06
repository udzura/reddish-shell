require 'fileutils'
require 'shellwords'

MRUBY_VERSION="2.1.0"

file :mruby do
  #sh "git clone --depth=1 https://github.com/mruby/mruby"
  sh "curl -L --fail --retry 3 --retry-delay 1 https://github.com/mruby/mruby/archive/#{MRUBY_VERSION}.tar.gz -s -o - | tar zxf -"
  FileUtils.mv("mruby-#{MRUBY_VERSION}", "mruby")
end

APP_NAME=ENV["APP_NAME"] || "reddish"
APP_ROOT=ENV["APP_ROOT"] || File.expand_path(__dir__)
require File.join(APP_ROOT, "mrblib", "reddish", "version.rb")
# avoid redefining constants in mruby Rakefile
mruby_root=File.expand_path(ENV["MRUBY_ROOT"] || "#{APP_ROOT}/mruby")
mruby_config=File.expand_path(ENV["MRUBY_CONFIG"] || "build_config.rb")
ENV['MRUBY_ROOT'] = mruby_root
ENV['MRUBY_CONFIG'] = mruby_config
Rake::Task[:mruby].invoke unless Dir.exist?(mruby_root)
Dir.chdir(mruby_root)
load "#{mruby_root}/Rakefile"

namespace :docker do
  task :build => [:objclean] do
    if `docker images -q reddish-build`.empty?
      dockerdir = File.join(APP_ROOT, "docker")
      `docker build -t reddish-build #{dockerdir}`
    end
    sh [
      "docker", "run", "--rm", "-v", "#{APP_ROOT}:/reddish",
      "reddish-build", "rake", "release"
    ].shelljoin
  end
end

task :release => [:all] do
  bindir = File.join(APP_ROOT, "bin")
  %W(#{mruby_root}/bin/#{APP_NAME}).each do |bin|
    next unless File.exist?(bin)
    sh "strip --strip-unneeded #{bin}"
    FileUtils.cp(bin, File.join(bindir, "#{APP_NAME}"))
  end
  sh "cd #{bindir}; tar zcf #{APP_NAME}-#{Reddish::VERSION}.tar.gz #{APP_NAME}"
end

namespace :test do
  desc "run mruby & unit tests"
  # only build mtest for host
  task :mtest => :all do
    # in order to get mruby/test/t/synatx.rb __FILE__ to pass,
    # we need to make sure the tests are built relative from mruby_root
    MRuby.each_target do |target|
      # only run unit tests here
      target.enable_bintest = false
      run_test if target.test_enabled?
    end
  end

  def clean_env(envs)
    old_env = {}
    envs.each do |key|
      old_env[key] = ENV[key]
      ENV[key] = nil
    end
    yield
    envs.each do |key|
      ENV[key] = old_env[key]
    end
  end

  desc "run integration tests"
  task :bintest => :all do
    MRuby.each_target do |target|
      clean_env(%w(MRUBY_ROOT MRUBY_CONFIG)) do
        run_bintest if target.bintest_enabled?
      end
    end
  end
end

desc "run all tests"
Rake::Task['test'].clear
task :test => ["test:mtest", "test:bintest"]

desc "cleanup"
Rake::Task['clean'].clear
task :clean do
  MRuby.each_target do |t|
    build_dir = File.join(t.build_dir, "mrbgems")
    gem_build_dirs = t.gem_dir_to_repo_url.values.map{|g| File.join(build_dir, File.basename(g))}
    gem_build_dirs << File.join(build_dir, APP_NAME)
    gem_build_dirs << File.join(build_dir, "mruby-reddish-parser")
    gem_build_dirs << File.join(build_dir, "mruby-bin-fdtest")
    FileUtils.rm_rf(gem_build_dirs, **{verbose: true, secure: true})
  end
end

task :objclean do
  objdirs = Dir.glob("#{MRUBY_ROOT}/build/*").select{|path| path !~ %r{/repos$}}
  unless objdirs.empty?
    FileUtils.rm_rf(objdirs, **{verbose: true, secure: true})
  end
end
