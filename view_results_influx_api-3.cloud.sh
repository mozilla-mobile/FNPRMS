
# WHERE "product" = 'fenix-nightly' AND "device" = 'pixel-2'
# FROM "main-post-onboard"
# FROM "view"

influx -host hilldale-b40313e5.influxcloud.net -port 8086 -username performance_ro -password 8cd4376a09477b73aab63dadd3d893f1 -ssl -execute 'SELECT * FROM "view" LIMIT 1000' -database="performance" -precision=rfc3339
