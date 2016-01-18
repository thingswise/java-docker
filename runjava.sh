#!/dumb-init /bin/bash
debug=${DEBUG:-0}

if [ $debug -ne 0 ]; then
  set -x
fi

cassandra=${CASSANDRA:-cassandra}
wd=${JAVA_WORKDIR:-.}
cp=${JAVA_CLASSPATH:-.}
jvmopts=${JVM_OPTS:-}
archive=${APP_ARCHIVE:-}
main=$1
shift 
args=$*

if [ -z $main ]; then
  echo "No main class supplied"
  exit 1
fi

function start_java() {
  if [ -f .lock ]; then
    return
  fi
  touch .lock
  echo "(Re)starting java..."
  actual_cp="$cp"
  if [ ! -z $archive ]; then
    echo "Listing archives at ${archive}..."
    tgz=$(ls -t $archive|head -1)
    if [ ! -z $tgz ]; then
      echo "Newest one is: $tgz"
      main_dir=$wd/.dist
      modified_cp=$(echo $cp|awk 'BEGIN {FS=":"} { for (i=1;i<=NF;i++) { print $i; }}'|while read d; do if [[ $d == /* ]]; then echo "$d"; else echo "$main_dir/$d"; fi done|tr "\n" ":")$wd
      actual_cp="$modified_cp"
      echo "Modified classpath: $actual_cp"
      echo "Unpacking in ${main_dir}..."
      (rm -rf $main_dir; mkdir -p $main_dir && cd $main_dir && tar zxf $archive/$tgz --strip=1) || exit 3
    fi
  fi
  cd $wd
  exec java $jvmopts -cp "$actual_cp" $main $args
}

rm -f .lock
start_java
