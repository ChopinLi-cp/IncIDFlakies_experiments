#!/usr/bin/env bash

# This script is used to only run iDFlakies for 10 times (at the same time record the time)
# find . -d -name ".dtfixingtools*" | xargs rm -rf # remove all the dirty info

if [[ $1 == "" ]]; then
    echo "arg1 - full path to the commits.csv file (eg. data/commits.csv)"
    exit
fi

currentDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

input=$1
inputProj=$currentDir"/../../projects"

pom_modify_script=$currentDir/../pom-modify/modify-project.sh
inc_pom_modify_script=$currentDir/../inc-pom-modify/modify-project.sh

IDFLAKIESOPTIONS="-Ddt.detector.roundsemantics.total=true -Ddetector.detector_type=random-class-method -Ddt.randomize.rounds=10 -Ddt.detector.original_order.all_must_pass=false -Ddt.verify.rounds=0"
MVNOPTIONS="-Ddependency-check.skip=true -Denforcer.skip=true -Drat.skip=true -Dmdep.analyze.skip=true -Dmaven.javadoc.skip=true -Dgpg.skip -Dlicense.skip=true -Dcheckstyle.skip=true"
SKIPTESTSOPTIONS="-DskipTests=true"

while IFS= read -r line
do
  if [[ ${line} =~ ^\# ]]; then 
    continue
  fi

  slug=$(echo $line | cut -d',' -f1)
  module=$(echo $line | cut -d',' -f2)
  test=$(echo $line | cut -d',' -f3)

  if [[ $module == "." ]]; then
    PL=""
    PL0=""
  else
    PL="-pl $module -am"
    PL0="-pl $module,dependencies-bom"
  fi

  firstsha=$(echo ${line} | rev | cut -d',' -f1 | rev)
  for revsecondsha in $(echo ${line} | cut -d',' -f4- | rev | cut -d',' -f2- | sed 's;,; ;g'); 
  do 
    secondsha=$(echo ${revsecondsha} | rev) 
    sec_short_sha=${secondsha: 0: 7}
    
    if [[ ! -d ${inputProj}/${slug}/${module}/.dtfixingtools_baseline_${sec_short_sha} ]]; then
      (
        cd ${inputProj}/${slug}
        git stash
        git checkout -f $secondsha
        mvn clean install ${PL} ${MVNOPTIONS} ${SKIPTESTSOPTIONS}
        $pom_modify_script $inputProj/$slug/${module}
        if [[ ${slug} = "apache/incubator-dubbo" ]]; then
          if [ ${module} = "dubbo-common" -o ${module} = "dubbo-config/dubbo-config-spring" ]; then
            mvn testrunner:testplugin ${PL0} ${MVNOPTIONS} ${IDFLAKIESOPTIONS}
            mv $inputProj/$slug/$module/.dtfixingtools $inputProj/$slug/$module/.dtfixingtools_baseline_${sec_short_sha}
          else
            mvn testrunner:testplugin ${PL} ${MVNOPTIONS} ${IDFLAKIESOPTIONS}
          fi
        else
          mvn testrunner:testplugin ${PL} ${MVNOPTIONS} ${IDFLAKIESOPTIONS}
        fi
        mv $module/.dtfixingtools $module/.dtfixingtools_baseline_${sec_short_sha}
      )
    fi
    firstsha=${secondsha}
  done
done < "$input"
# $pom_modify_script $inputProj/$slug
