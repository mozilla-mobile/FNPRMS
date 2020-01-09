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

function validate_use_case {
  use_case=$1

  case ${use_case} in
    ha|al|hanoob)
      ;;
    *)
      return 1
      ;;
  esac

  return 0
}

function validate_product {
  product=$1

  case ${product} in
    fennec|fenix-nightly|fenix-performance)
      ;;
    *)
      return 1
      ;;
  esac

  return 0
}

function package_name_for_product {
  product=$1
  shift

  validate_product ${product}
  if [ $? -ne 0 ]; then
    return 1
  fi
    case ${product} in
    fenix-nightly)
      echo "org.mozilla.fenix.nightly"
      ;;
    fenix-performance)
      echo "org.mozilla.fenix.performancetest"
      ;;
    fennec)
      echo "org.mozilla.firefox"
      ;;
  esac
  return 0
}

function intent_for_configuration {
  use_case=$1
  shift
  product=$1
  shift

  validate_use_case ${use_case}
  if [ $? -ne 0 ]; then
    return 1
  fi

  validate_product ${product}
  if [ $? -ne 0 ]; then
    return 1
  fi

  case ${use_case} in
    al)
      case ${product} in
        fenix-nightly)
          echo '-d "about:blank" -a android.intent.action.VIEW org.mozilla.fenix.nightly/org.mozilla.fenix.IntentReceiverActivity'
          ;;
        fenix-performance)
          echo '-d "about:blank" -a android.intent.action.VIEW org.mozilla.fenix.performancetest/org.mozilla.fenix.IntentReceiverActivity'
          ;;
        fennec)
          echo '-t "text/html" -d "about:blank" -a android.intent.action.VIEW org.mozilla.firefox/org.mozilla.gecko.LauncherActivity'
          ;;
      esac
      ;;
    ha)
      case ${product} in
        fenix-nightly)
          echo "-a android.intent.action.VIEW org.mozilla.fenix.nightly/org.mozilla.fenix.HomeActivity"
          ;;
        fenix-performance)
          echo "-a android.intent.action.VIEW org.mozilla.fenix.performancetest/org.mozilla.fenix.HomeActivity"
          ;;
        fennec)
          echo "-a android.intent.action.VIEW org.mozilla.firefox/org.mozilla.gecko.BrowserApp"
          ;;
      esac
      ;;
    hanoob)
      case ${product} in
        fenix-nightly)
          return 1
          ;;
        fenix-performance)
          return 1
          ;;
        fennec)
          return 1
          ;;
      esac
      ;;
  esac

  return 0
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

function run_test {
  apk=$1
  shift
  log_file=$1
  shift
  package_name=$1
  shift
  start_command=$1
  shift
  tests=$1
  shift
  finishonboarding=$1

  warmup_start_command=${start_command}
  if [ "Xtrue" == "X${finishonboarding}" ]; then
    warmup_start_command=`echo ${start_command} | sed 's/start-activity/start-activity --ez finishonboarding true/'`
  fi

  rm -f ${log_file} > /dev/null 2>&1
  maybe_create_file ${log_file}

  # do the apk installation.
  $ADB uninstall ${package_name} > /dev/null 2>&1
  $ADB install -t ${apk}

  if [ $? -ne 0 ]; then
    echo 'Error occurred installing the APK!' > ${log_file}
    return
  fi

  # Now, do a single start to get all that stuff out of the way.
  $ADB shell "${warmup_start_command}"
  # sleep here in case it takes a while for the app to start.
  # We don't want to stop it before it starts.
  sleep 5
  $ADB shell "am force-stop ${package_name}"

  # This will clear all processes that are 'safe to kill'. Do
  # this to try to eliminate noise.
  $ADB shell "am kill-all"


  # Clearing the log here so that we don't record the time of the
  # first start (above)
  $ADB logcat --clear
  $ADB logcat -G 2M

  for i in `seq ${tests}`; do
    echo "Starting by using ${start_command}"

    $ADB shell "${start_command}"

    # sleep here in case it takes a while for the app to start.
    # We don't want to stop it before it starts.
    sleep 5
    $ADB shell "input keyevent HOME"
    sleep 5
    $ADB shell "am force-stop ${package_name}"
  done;

  $ADB logcat -d >> ${log_file} 2>&1
}
