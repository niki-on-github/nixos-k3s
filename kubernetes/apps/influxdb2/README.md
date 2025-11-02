# InfluxDB2

InfluxDB is an open source time series database.

## Clone

Inside the old instance:

```sh
influx backup /tmp/backup -t <root-token>
```

Then copy the files from host and uplaod to the new instance:

```sh
mkldir backup
cd backup
kubectl cp monitoring/influxdb-55c74c9648-mf4wb:/tmp/backup .
cd ..
kubectl cp backup monitoring/influxdb2-0:/tmp
```

And finaly from new instance:

```sh
influx bucket delete -n solaredge -o homelab
influx restore /tmp/backup/ --bucket solaredge
```
