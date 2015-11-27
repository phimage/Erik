# Uncomment this line to define a global platform for your project

use_frameworks!
inhibit_all_warnings!

def dependency_pods
    pod 'Kanna'
    pod 'Eki'
    pod 'BrightFutures'
end

def testing_pods
    dependency_pods
    pod 'FileKit'
end

target 'Erik' do
    platform :ios, '9.0'
    dependency_pods
end

target 'ErikTests' do
    platform :ios, '9.0'
    testing_pods
end

target 'ErikOSX' do
    platform :osx, '10.10'
    dependency_pods
end

target 'ErikOSXTests' do
    platform :osx, '10.10'
    testing_pods
end
