# Example usage:
#   name='JUnit Jupiter' \
#   targets='org.junit.jupiter:junit-jupiter-api:5.3.1, \
#                org.junit.jupiter:junit-jupiter-api:5.3.1' \
#   j=1 s=1 ruby generate_fixture_file.rb
# You need mvn installed also
# TODO: Rewrite with optparse or something
require 'erb'
require 'tmpdir'
require 'yaml'
require_relative('../../../helpers/dir')

include Helpers

POM_ERB = <<-POM.freeze
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>org.grably</groupId>
    <artifactId>test</artifactId>
    <version>1.0-SNAPSHOT</version>
    <packaging>jar</packaging>

    <dependencies>
        <% targets.each do |group, artifact, version| %>
        <dependency>
            <groupId><%= group %></groupId>
            <artifactId><%= artifact %></artifactId>
            <version><%= version %></version>
        </dependency>
        <% end %>
    </dependencies>
</project>
POM

if ARGV.first
  config = YAML.load(IO.read(ARGV.first))
  targets = config['targets'].map { |t| t.split(':') }
  name = config['name']
  sources = config['sources']
  javadoc = config['javadoc']
else
  id = Dir['fixtures/*.yml'].size
  name = ENV['name']
  targets = ENV['targets'].split(',').map { |t| t.split(':') }
  sources = !ENV['s'].nil?
  javadoc = !ENV['j'].nil?
end

sums = Dir.mktmpdir do |tmp|
  Dir.chdir(tmp) do
    File.open('pom.xml', 'w') do |file|
      file << ERB.new(POM_ERB).result(binding)
    end

    puts `mvn dependency:copy-dependencies`
    puts `mvn dependency:copy-dependencies -Dclassifier=sources` if sources
    puts `mvn dependency:copy-dependencies -Dclassifier=javadoc` if javadoc

    describe_dir('target/dependency')
  end
end

filename = "maven_#{id.to_s.rjust(2, '0')}-#{name.downcase.tr(' ', '-')}.yml"
fixture = {
  'desc' => name,
  'sources' => sources,
  'javadoc' => javadoc,
  'targets' => targets.map { |t| t.join(':') },
  'sums' => sums
}

IO.write(File.join(__dir__, filename), YAML.dump(fixture))
