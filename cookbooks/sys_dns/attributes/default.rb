#
# Cookbook Name:: sys_dns
#
# Copyright RightScale, Inc. All rights reserved.
# All access and use subject to the RightScale Terms of Service available at
# http://www.rightscale.com/terms.php and, if applicable, other agreements
# such as a RightScale Master Subscription Agreement.

# Required attributes

# DNS service provider
node.default[:sys_dns][:choice] = ""
# DNS Record ID
node.default[:sys_dns][:id] = ""
# DNS user
node.default[:sys_dns][:user] = ""
# DNS password
node.default[:sys_dns][:password] = ""

# Optional attributes

# Cloud DNS region
node.default[:sys_dns][:region] = ""
