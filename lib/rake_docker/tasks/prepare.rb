require_relative '../tasklib'

module RakeDocker
  module Tasks
    class Prepare < TaskLib
      parameter :name, :default => :prepare
      parameter :image, :required => true

      parameter :work_directory, :required => true

      parameter :copy_spec, :default => []
      parameter :create_spec, :default => []

      def process_arguments(args)
        self.name = args[0] if args[0]
      end

      def define
        desc "Prepare for build of #{image} image"
        task name do
          image_directory = File.join(work_directory, image)
          mkdir_p image_directory

          copy_spec.each do |entry|
            from = entry.is_a?(Hash) ? entry[:from] : entry
            to = entry.is_a?(Hash) ?
                File.join(image_directory, entry[:to]) :
                image_directory

            if File.directory?(from)
              mkdir_p to
              cp_r from, to
            else
              cp from, to
            end
          end

          create_spec.each do |entry|
            content = entry[:content]
            to = entry[:to]
            file = File.join(image_directory, to)

            mkdir_p(File.dirname(file))
            File.open(file, 'w') do |f|
              f.write(content)
            end
          end
        end
      end
    end
  end
end

# [file1, file2, file3], dest_dir
# src_dir, dest_dir

# create file with content

# image_directory = 'build/image'
# mkdir_p image_directory
#
# [
#     'Dockerfile',
#     'scripts/image/authentication-service.sh',
#     'src/changeProxy.xsl'
# ].each do |f|
#   cp f, image_directory
# end
#
# File.open(File.join(image_directory, 'VERSION'), 'w') do |f|
#   f.write(configuration.version.to_s)
# end
# File.open(File.join(image_directory, 'TAG'), 'w') do |f|
#   f.write(configuration.version.to_docker_tag)
# end


# image_directory = 'build/image'
# mkdir_p image_directory
#
# ['Dockerfile', 'scripts/image/entrypoint.sh'].each do |f|
#   cp f, image_directory
# end
#
# File.open(File.join(image_directory, 'VERSION'), 'w') do |f|
#   f.write(configuration.version.to_s)
# end
# File.open(File.join(image_directory, 'TAG'), 'w') do |f|
#   f.write(configuration.version.to_docker_tag)
# end


# image_directory = 'build/image'
# mkdir_p image_directory
#
# ['Dockerfile', 'scripts/image/core-banking-gateway.sh'].each do |f|
#   cp f, image_directory
# end
#
# cp "build/app/uberjar/core-banking-gateway-#{configuration.version.to_s}-standalone.jar",
#    File.join(image_directory, 'core-banking-gateway-standalone.jar')
#
# File.open(File.join(image_directory, 'VERSION'), 'w') do |f|
#   f.write(configuration.version.to_s)
# end
# File.open(File.join(image_directory, 'TAG'), 'w') do |f|
#   f.write(configuration.version.to_docker_tag)
# end


# version = configuration.version
# image_directory = 'build/image'
# mkdir_p image_directory
#
# ['Dockerfile', 'scripts/image/customer-service.sh'].each do |f|
#   cp f, image_directory
# end
#
# cp "build/app/uberjar/customer-service-#{version.to_s}-standalone.jar",
#    File.join(image_directory, 'customer-service-standalone.jar')
#
# File.open(File.join(image_directory, 'VERSION'), 'w') do |f|
#   f.write(version.to_s)
# end
# File.open(File.join(image_directory, 'TAG'), 'w') do |f|
#   f.write(version.to_docker_tag)
# end


# image_directory = 'build/image'
# code_directory = File.join(image_directory, 'code')
#
# mkdir_p image_directory
# mkdir_p code_directory
#
# [
#     'Dockerfile',
#     'package.json',
#     'yarn.lock'
# ].each do |f|
#   cp f, image_directory
# end
#
# cp_r 'build/app/.', code_directory
#
# File.open(File.join(image_directory, 'VERSION'), 'w') do |f|
#   f.write(configuration.version.to_s)
# end
# File.open(File.join(image_directory, 'TAG'), 'w') do |f|
#   f.write(configuration.version.to_docker_tag)
# end


# version = configuration.version
# image_directory = 'build/image'
# mkdir_p image_directory
#
# ['Dockerfile', 'scripts/image/notification-service.sh'].each do |f|
#   cp f, image_directory
# end
#
# cp "build/app/uberjar/notification-service-#{version.to_s}-standalone.jar",
#    File.join(image_directory, 'notification-service-standalone.jar')
#
# File.open(File.join(image_directory, 'VERSION'), 'w') do |f|
#   f.write(version.to_s)
# end
# File.open(File.join(image_directory, 'TAG'), 'w') do |f|
#   f.write(version.to_docker_tag)
# end


# image_directory = 'build/image'
# mkdir_p image_directory
#
# ['Dockerfile', 'scripts/image/offline-transaction-service.sh'].each do |f|
#   cp f, image_directory
# end
#
# cp "build/app/uberjar/offline-transaction-service-#{configuration.version.to_s}-standalone.jar",
#    File.join(image_directory, 'offline-transaction-service-standalone.jar')
#
# File.open(File.join(image_directory, 'VERSION'), 'w') do |f|
#   f.write(configuration.version.to_s)
# end
# File.open(File.join(image_directory, 'TAG'), 'w') do |f|
#   f.write(configuration.version.to_docker_tag)
# end


# image_directory = 'build/image'
# mkdir_p image_directory
#
# ['Dockerfile', 'scripts/image/payment-service.sh'].each do |f|
#   cp f, image_directory
# end
#
# cp "build/app/uberjar/payment-service-#{configuration.version.to_s}-standalone.jar",
#    File.join(image_directory, 'payment-service-standalone.jar')
#
# File.open(File.join(image_directory, 'VERSION'), 'w') do |f|
#   f.write(configuration.version.to_s)
# end
# File.open(File.join(image_directory, 'TAG'), 'w') do |f|
#   f.write(configuration.version.to_docker_tag)
# end


# image_directory = 'build/pipeline-builder/image'
#
# mkdir_p image_directory
#
# ['src/pipeline-builder/Dockerfile'].each do |f|
#   cp f, image_directory
# end
#
# File.open(File.join(image_directory, 'VERSION'), 'w') do |f|
#   f.write(configuration.version.to_s)
# end
# File.open(File.join(image_directory, 'TAG'), 'w') do |f|
#   f.write(configuration.version.to_docker_tag)
# end


# image_directory = 'build/image'
# mkdir_p image_directory
#
# ['Dockerfile', 'scripts/image/template-service.sh'].each do |f|
#   cp f, image_directory
# end
#
# cp "build/app/uberjar/template-service-#{configuration.version.to_s}-standalone.jar",
#    File.join(image_directory, 'template-service-standalone.jar')
#
# File.open(File.join(image_directory, 'VERSION'), 'w') do |f|
#   f.write(configuration.version.to_s)
# end
# File.open(File.join(image_directory, 'TAG'), 'w') do |f|
#   f.write(configuration.version.to_docker_tag)
# end


# image_directory = 'build/image'
# mkdir_p image_directory
#
# cp_r 'src/vpn-server/.', image_directory
#
# File.open(File.join(image_directory, 'VERSION'), 'w') do |f|
#   f.write(configuration.version.to_s)
# end
# File.open(File.join(image_directory, 'TAG'), 'w') do |f|
#   f.write(configuration.version.to_docker_tag)
# end