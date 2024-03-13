# geoip2-haproxy

GeoIP2 country blocking with HAProxy.

Downloads GeoLite2 country .csv, splits it into per-country .txt files and copies them over to a OPNsense instance via SSH to the following path:

```/etc/haproxy/geoip2```

Generated file contents are public IPv4 and IPv6 subnets, compatible with HAProxy ACL (Access Control Lists).

Content example of ```US.txt``` file, containing all public subnets which belong to the United States:

```
...
99.88.0.0/13
99.96.0.0/11
9.9.9.9/32
2000:db8::/32
2001:146c::/32
2001:146f::/32
...
```

## Usage

### System environment requirements

Make sure you are running this script on a Linux distribution with passwordless remote SSH access to your OPNsense instance (SSH public key authentication).
The remote user needs to have administrative privileges on your OPNsense instance.

### MaxMind License Key

Since 2020, MaxMind now requires a registration in order to download free GeoIP2 databases.

Register at maxmind.com, go to "My account" -> "Manage License Keys" and generate a new license key.
You will also find your account ID there which is needed for this script since Maxmind has changed the according API in the early year of 2024.

### Pull latest GeoIP2 data and make necessary adjustments
```
git clone https://github.com/Grandma-Betty/geoip2-haproxy.git
cd geoip2-haproxy
chmod +x ./getMaxMindGeo2Lite.sh
vi ./getMaxMindGeo2Lite.sh
```

### Adjust the following script header's variables according to your environment (change user and port only if required)
```
YOUR_ACCOUNT_ID="<Your_MaxMind_AccountID>"
YOUR_LICENSE_KEY="<Your_MaxMind_LicenseKey>"
OPNSENSE_HOST="<your_opnsense_hostname_or_ip_address>"
OPNSENSE_USER="root"
OPNSENSE_SSH_PORT="22"
```

### Run the script
```
./getMaxMindGeo2Lite.sh
```

### Add ACL to HAProxy
```
acl acl_CN src -f /etc/haproxy/geoip2/CN.txt
acl acl_US src -f /etc/haproxy/geoip2/US.txt

http-request deny if !acl_CN
http-request deny if !acl_US
```

The above example rejects connections from China and the United States.

### Cron

GeoLite2 Country database is [updated twice weekly, every Tuesday and Friday](https://dev.maxmind.com/geoip/geoip2/geolite2/).

Add the following cronjob if you wish to stay up to date (replace `/path/to/script`
with your script path). It pulls latest updates every Wednesday at 06:00 AM.

``
0 6 * * 3 '/path/to/script/getMaxMindGeo2Lite.sh
``
