#!/usr/bin/env bash

if [[ $1 == "" ]]; then
    cho "arg1 - full path to the victim csv file (eg. data/victim.csv)"
    exit
fi

currentDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
echo "$currentDir"

input=$1
inputProjRoot=$currentDir"/../projects"
echo "$input"

while IFS= read -r line
do
  slug=$(echo $line | cut -d',' -f1)
  module=$(echo $line | cut -d',' -f2)
  odtest=$(echo $line | cut -d',' -f3)

  if [[ ${line} = "\#*" ]]; then continue; fi
  if [[ ! -d ${inputProjRoot}/${slug} ]]; then
    git clone "https://github.com/$slug" $inputProjRoot/$slug
    (
        cd $inputProjRoot/$slug
    )
    MVNOPTIONS="-Ddependency-check.skip=true -Denforcer.skip=true -Drat.skip=true -Dmdep.analyze.skip=true -Dmaven.javadoc.skip=true -Dgpg.skip -Dlicense.skip=true -Dcheckstyle.skip=true"
    if [[ $module == "." ]]; then
      PL=""
    else
      PL="-pl $module -am"
    fi
    echo "module: $module"
    (
        cd $inputProjRoot/$slug
        mvn clean install ${PL} ${MVNOPTIONS}
    )
  fi
done < "$input"

