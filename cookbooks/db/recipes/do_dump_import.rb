#
# Cookbook Name:: db
#
# Copyright RightScale, Inc. All rights reserved.  All access and use subject to the
# RightScale Terms of Service available at http://www.rightscale.com/terms.php and,
# if applicable, other agreements such as a RightScale Master Subscription Agreement.

rightscale_marker :begin

# Check for valid prefix / dump filename
dump_file_regex = '(^\w+)(-\d{1,12})*$'
raise "Prefix: #{node[:db][:dump][:prefix]} invalid.  It is restricted to word characters (letter, number, underscore) and an optional partial timestamp -YYYYMMDDHHMM.  (=~/#{dump_file_regex}/ is the ruby regex used). ex: myapp_prod_dump, myapp_prod_dump-201203080035 or myapp_prod_dump-201203" unless node[:db][:dump][:prefix] =~ /#{dump_file_regex}/ || node[:db][:dump][:prefix] == ""

# Check variables and log/skip if not set
skip, reason = true, "DB/Schema name not provided" if node[:db][:dump][:database_name] == ""
skip, reason = true, "Prefix not provided" if node[:db][:dump][:prefix] == ""
skip, reason = true, "Storage account provider not provided" if node[:db][:dump][:storage_account_provider] == ""
skip, reason = true, "Container not provided" if node[:db][:dump][:container] == ""

if skip
  log "  Skipping import: #{reason}"
else

  db_name = node[:db][:dump][:database_name]
  prefix = node[:db][:dump][:prefix]
  dumpfilepath_without_extension = "/tmp/" + prefix
  container = node[:db][:dump][:container]
  cloud = node[:db][:dump][:storage_account_provider]
  command_to_execute = "/opt/rightscale/sandbox/bin/ros_util get"
  command_to_execute << " --cloud #{cloud} -- container #{container}"
  command_to_execute << " --dest #{dumpfilepath_without_extension}"
  command_to_execute << " --source #{prefix} --latest"

  # Obtain the dumpfile from ROS
  execute "Download dumpfile from Remote Object Store" do
    command command_to_execute
    creates dumpfilepath_without_extension
    environment ({
      'STORAGE_ACCOUNT_ID' => node[:db][:dump][:storage_account_id],
      'STORAGE_ACCOUNT_SECRET' => node[:db][:dump][:storage_account_secret]
    })
  end

  # Detect the compression type of the downloaded file
  ruby_block "Detect compression type" do
    block do
      extension = ""
      if `file #{dumpfilepath_without_extension}` =~ /Zip archive data/
        extension = "zip"
      elsif `file #{dumpfilepath_without_extension}` =~ /gzip compressed data/
        extension = "gz"
      elsif `file #{dumpfilepath_without_extension}` =~ /bzip2 compressed data/
        extension = "bz2"
      end
    end
  end

  # Add the detected extension to the filename prefix
  dumpfilepath = "#{dumpfilepath_without_extension}.#{extension}"

  # Set the correct extension for the downloaded file
  execute "Setting extension to downloaded file" do
    command "mv #{dumpfilepath_without_extension} #{dumpfilepath}"
    creates dumpfilepath
  end

  # Restore the dump file to db
  # See cookbooks/db_<provider>/providers/default.rb for the
  # "restore_from_dump_file" action.
  db node[:db][:data_dir] do
    dumpfile dumpfilepath
    db_name db_name
    action :restore_from_dump_file
  end

  # Delete the local file.
  file dumpfilepath do
    backup false
    action :delete
  end

end

rightscale_marker :end
