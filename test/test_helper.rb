$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'simplecov'
require 'ass_maintainer/info_base'
require 'ass_ole'
require 'ass_ole/snippets/shared'
require 'minitest/autorun'
require 'mocha/mini_test'

module AssOle::Snippets::SharedTest
  PLATFORM_REQUIRE = '~> 8.3.10.0'
  module Tmp
    extend AssLauncher::Api
    TMP_DIR = Dir.tmpdir
    TMP_IB_NAME = self.name.gsub('::','_')
    TMP_IB_PATH = File.join TMP_DIR, TMP_IB_NAME
    TMP_IB_CS = cs_file file: TMP_IB_PATH
    TMP_IB = AssMaintainer::InfoBase.new TMP_IB_NAME, TMP_IB_CS, false
    TMP_IB.rebuild! :yes
  end

  FIXT_DIR = File.expand_path('../fixtures', __FILE__)

  EXT_RUNTIME = Module.new do
    is_ole_runtime :external
  end
  EXT_RUNTIME.run Tmp::TMP_IB

  THICK_RUNTIME = Module.new do
    is_ole_runtime :thick
  end
  THICK_RUNTIME.run Tmp::TMP_IB
end
