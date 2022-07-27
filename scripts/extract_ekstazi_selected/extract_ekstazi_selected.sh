#!/usr/bin/env bash

# NOTE: This script is used to extract the information according to the input

if [[ $1 == "" ]]; then
	echo "arg1 - full path to the input file (eg. data/commits.csv)"
	exit
fi

currentDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

input=$1
inputProj=$currentDir"/../../projects"

ekstaziSelectedTestsRootDir=$currentDir"/../../data/ekstazi-selected-tests"
mkdir -p ${ekstaziSelectedTestsRootDir} 2>/dev/null

ekstaziDependenciesRootDir=$currentDir"/../../data/ekstazi-dependencies"
mkdir -p ${ekstaziDependenciesRootDir} 2>/dev/null

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

		ekstaziSelectedTestsDir=${ekstaziSelectedTestsRootDir}/${slug}/${module}/${sec_short_sha}
		mkdir -p ${ekstaziSelectedTestsDir} 2>/dev/null

    ekstaziDependenciesDir=${ekstaziDependenciesRootDir}/${slug}/${module}/${sec_short_sha}
		mkdir -p ${ekstaziDependenciesDir} 2>/dev/null

		EXISTING_FILE=`ls ${inputProj}/${slug}/${module}/.ekstazi-${sec_short_sha}/selected-tests 2>/dev/null`
		if [[ -f ${EXISTING_FILE} ]]; then
			cp ${inputProj}/${slug}/${module}/.ekstazi-${sec_short_sha}/selected-tests ${ekstaziSelectedTestsDir}/selected-tests
		fi

		if [[ -f ${ekstaziDependenciesDir}/dependencies ]]; then
			rm ${ekstaziDependenciesDir}/dependencies
		fi
		echo -n "" >> ${ekstaziDependenciesDir}/dependencies
		cd ${inputProj}/${slug}/${module}
		dlist=$(ls .ekstazi-${sec_short_sha}/*.clz)
		for line in $dlist
		do
			dependentTest_tmp1=$(echo ${line#*/})
			dependentTest=$(echo ${dependentTest_tmp1%.clz})
			print_string=$dependentTest
			for i in $(cat ${line})
			do
				if [[ $i == file:* ]]; then
					if [[ $i == */target/classes/* ]]; then
						dep_tmp1=$(echo ${i#*/target/classes/})
						dep_tmp2=$(echo ${dep_tmp1%.class})
						dep_tmp3=$(echo ${dep_tmp2%%\$*})
						dep=$(echo $dep_tmp3 | sed 's/\//./g')
						if [[ $print_string =~ ,$dep ]]; then
							print_string=$print_string
						else
							print_string=$print_string,$dep
						fi
					elif [[ $i == */target/test-classes/* ]]; then
						dep_tmp1=$(echo ${i#*/target/test-classes/})
						dep_tmp2=$(echo ${dep_tmp1%.class})
						dep_tmp3=$(echo ${dep_tmp2%%\$*})
						dep=$(echo $dep_tmp3 | sed 's/\//./g')
						if [[ $print_string =~ ,$dep ]]; then
							print_string=$print_string
						else
							print_string=$print_string,$dep
						fi
					fi
				fi
			done
			echo $print_string >> ${ekstaziDependenciesDir}/dependencies
		done
	done
	firstsha=${secondsha}
done < "$input"
