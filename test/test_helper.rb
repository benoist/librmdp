require 'simplecov'
SimpleCov.start

$LOAD_PATH << File.expand_path('../../lib', __FILE__)
$LOAD_PATH << File.expand_path('../../test', __FILE__)

require 'minitest/autorun'
require 'librmdp'
