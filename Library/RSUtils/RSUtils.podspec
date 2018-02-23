#
# Be sure to run `pod lib lint RSUtils.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "RSUtils"
  s.version          = "0.2.4"
  s.summary          = "Some common functions"
  s.description      = <<-DESC
                       Sum common function
                       DESC
  s.homepage         = "http://dev.runsystem.vn/commons-ios/rsutils"
  s.license          = 'Private'
  s.author           = { "Phạm Quang Dương" => "duongpq@runsystem.net" }
  s.source           = { :git => "git@dev.runsystem.vn:commons-ios/rsutils.git", :branch => 'version/' + s.version.to_s }

  s.platform     = :osx, '10.9'
  s.requires_arc = true
  s.source_files = 'Classes/**/*'
end
