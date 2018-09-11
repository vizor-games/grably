desc 'Drop .grably directory with all intermediate build files'
task :clean do
  puts ' * '.green.bright + 'Cleaning profiles and temporary directorires:'
  Dir['.grably/*'].each do |e|
    puts '  -- '.white.bright + e
  end
  FileUtils.rm_rf('.grably')
end
