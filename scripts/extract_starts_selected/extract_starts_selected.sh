#!/usr/bin/env bash

# NOTE: This script is used to extract the information according to the input

if [[ $1 == "" ]]; then
	echo "arg1 - full path to the input file (eg. data/commits.csv)"
	exit
fi

currentDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

input=$1
inputProj=$currentDir"/../../projects"

startsSelectedTestsRootDir=$currentDir"/../../data/starts-selected-tests"
mkdir -p ${startsSelectedTestsRootDir} 2>/dev/null

startsDependenciesRootDir=$currentDir"/../../data/starts-dependencies"
mkdir -p ${startsDependenciesRootDir} 2>/dev/null

while IFS= read -r line
do
  if [[ ${line} =~ ^\# ]]; then 
    continue
  fi

  slug=$(echo $line | cut -d',' -f1)
  module=$(echo $line | cut -d',' -f2)
  test=$(echo $line | cut -d',' -f3)
  
  firstsha=$(echo ${line} | rev | cut -d',' -f1 | rev)
  for revsecondsha in $(echo ${line} | cut -d',' -f4- | rev | cut -d',' -f2- | sed 's;,; ;g'); 
  do 
    secondsha=$(echo ${revsecondsha} | rev) 
    sec_short_sha=${secondsha: 0: 7}

		startsSelectedTestsDir=${startsSelectedTestsRootDir}/${slug}/${module}/${sec_short_sha}
		mkdir -p ${startsSelectedTestsDir} 2>/dev/null

    startsDependenciesDir=${startsDependenciesRootDir}/${slug}/${module}/${sec_short_sha}
		mkdir -p ${startsDependenciesDir} 2>/dev/null

		EXISTING_FILE=`ls ${inputProj}/${slug}/${module}/.starts-${sec_short_sha}/selected-tests 2>/dev/null`
		if [[ -f ${EXISTING_FILE} ]]; then
			cp ${inputProj}/${slug}/${module}/.starts-${sec_short_sha}/selected-tests ${startsSelectedTestsDir}/selected-tests
		fi

		if [[ -f ${startsDependenciesDir}/dependencies ]]; then
			rm ${startsDependenciesDir}/dependencies
		fi
		echo -n "" >> ${startsDependenciesDir}/dependencies
		cd ${inputProj}/${slug}/${module}
		dlist=`ls .starts-${sec_short_sha}/deps.zlc 2>/dev/null`
    if [[ ! -f ${dlist} ]]; then
      continue
    fi
    cat $dlist | while read line
    do
      if [[ $line == file:* ]]; then
        if [[ $line == */target/classes/* ]]; then
          deps=$(echo $line | cut -d' ' -f3)
          dep_tmp0=$(echo $line | cut -d' ' -f1)
          dep_tmp1=$(echo ${dep_tmp0#*/target/classes/})
          dep_tmp2=$(echo ${dep_tmp1%.class})
          dep_tmp3=$(echo ${dep_tmp2%%\$*})
          dep=$(echo $dep_tmp3 | sed 's/\//./g')
          print_string=$dep,$deps
          echo $print_string >> ${startsDependenciesDir}/dependencies
        elif [[ $line == */target/test-classes/* ]]; then
          deps=$(echo $line | cut -d' ' -f3)
          dep_tmp0=$(echo $line | cut -d' ' -f1)
          dep_tmp1=$(echo ${dep_tmp0#*/target/test-classes/})
          dep_tmp2=$(echo ${dep_tmp1%.class})
          dep_tmp3=$(echo ${dep_tmp2%%\$*})
          dep=$(echo $dep_tmp3 | sed 's/\//./g')
          print_string=$dep,$deps
          echo $print_string >> ${startsDependenciesDir}/dependencies
        fi
      fi
    done
	done
	firstsha=${secondsha}
done < "$input"
