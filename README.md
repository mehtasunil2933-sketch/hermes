# hermes

### random secret key
```
openssl rand -hex 32
```

### backup hermes
```
cd /tmp && rclone copy r2:$R2_BUCKET/hermes/latest.zip .
hermes import /tmp/latest.zip
```
