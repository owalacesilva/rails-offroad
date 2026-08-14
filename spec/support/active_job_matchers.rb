# have_enqueued_mail / have_enqueued_job vêm do rspec-rails, mas comparam
# argumentos com uma classe do rspec-mocks. Como o projeto usa mocha
# (config.mock_with :mocha em spec/spec_helper.rb), o rspec-mocks não é
# carregado inteiro — este require traz só a peça de que os matchers precisam.
require "rspec/mocks/argument_list_matcher"
