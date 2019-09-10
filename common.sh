function download_apk { 
  url_template=$1
  shift
  output_file_path=$1
  date_to_fetch=`date +"%Y.%-m.%-d"`;

  # If the apk already exists, don't bother getting it again.
  if [ -e $output_file_path ]; then
    return 0
  fi

  apk_download_url=`echo $apk_url_template | sed "s/DATE/${date_to_fetch}/g"`;
  curl -fsL --create-dirs --output $output_file_path $apk_download_url 2>&1 > /dev/null
  return $?
}

function maybe_create_dir {

  filedir=$1

  mkdir -p $filedir >/dev/null 2>&1
}

function maybe_create_file {
  filepath=$1
  another=0

  maybe_create_dir $(dirname $filepath)
  touch $filepath
}
