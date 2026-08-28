#!/bin/bash

set -eux

# Make sure Apache is installed and running.
systemctl enable httpd || true
systemctl start httpd || true

# Create the web page.
cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Netology LAMP Instance Group</title>
</head>
<body>

<h1>Netology LAMP Instance Group</h1>

<p>
    This page is running on a VM created by Yandex Cloud Instance Group.
</p>

<p>
    Hostname:
    <strong>$(hostname)</strong>
</p>

<p>
    Image from Yandex Object Storage:
</p>

<p>
    <a href="${image_url}" target="_blank">
        <img
            src="${image_url}"
            alt="Image from Yandex Object Storage"
            style="max-width: 800px;"
        >
    </a>
</p>

</body>
</html>
EOF

# Make sure Apache serves the page.
systemctl restart httpd