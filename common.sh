ADB="/home/hawkinsw/Android/Sdk/platform-tools/adb"

function sweep_files_older_than {
  days=$1
  shift
  path=$1

  to_delete=`find $path -name '*' -and -type f -and -true -and -ctime +$days | grep -v git`
  for i in ${to_delete}; do
    git rm ${i}
  done
}

function download_apk { 
  url_template=$1
  shift
  date_to_fetch=$1
  shift
  output_file_path=$1
  result=0

  # If the apk already exists, don't bother getting it again.
  if [ -e ${output_file_path} ]; then
    echo "Not downloading a new apk; using existing."
    return 0
  fi

  apk_download_url=`echo ${apk_url_template} | sed "s/DATE/${date_to_fetch}/g"`;
  echo "Downloading apk."
  curl -fsL --create-dirs --output ${output_file_path} ${apk_download_url} 2>&1 > /dev/null
  result=$?
  echo "Done downloading apk."
  return ${result}
}

function maybe_create_dir {
  filedir=$1
  mkdir -p ${filedir} >/dev/null 2>&1
}

function maybe_create_file {
  filepath=$1
  maybe_create_dir $(dirname ${filepath})
  touch ${filepath}
}
