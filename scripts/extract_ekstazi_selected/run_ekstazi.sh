#!/bin/bash

if [[ $1 == "" ]]; then
  echo "arg1 - full path to the test file (eg. data/commits.csv)"
  exit
fi

currentDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

input=$1
inputProj=$currentDir"/../../projects"

pom_modify_script=$currentDir/../ekstazi-pom-modify/modify-project.sh

MVNOPTIONS="-Ddependency-check.skip=true -Dgpg.skip=true -DfailIfNoTests=false -Dskip.installnodenpm -Dskip.npm -Dskip.yarn -Dlicense.skip -Dcheckstyle.skip -Drat.skip -Denforcer.skip -Danimal.sniffer.skip -Dmaven.javadoc.skip -Dfindbugs.skip -Dwarbucks.skip -Dmodernizer.skip -Dimpsort.skip -Dmdep.analyze.skip -Dpgpverify.skip -Dxml.skip -Dcobertura.skip=true -Dfindbugs.skip=true -Dmdep.analyze.skip=true -Dmaven.javadoc.skip=true -Dmaven.test.failure.ignore=true"
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
    PL0="-pl $module,dependencies-bom -am"
  fi

  firstsha=$(echo ${line} | rev | cut -d',' -f1 | rev)
  for revsecondsha in $(echo ${line} | cut -d',' -f4- | rev | cut -d',' -f2- | sed 's;,; ;g'); 
  do 
    secondsha=$(echo ${revsecondsha} | rev) 
    sec_short_sha=${secondsha: 0: 7}

    if [[ ! -d ${inputProj}/${slug}/${module}/.ekstazi-${sec_short_sha} ]]; then
    (
      cd ${inputProj}/${slug}
      find -name ".ekstazi" | xargs rm -rf
      git stash
      git checkout -f $firstsha
      mvn clean install ${PL} ${MVNOPTIONS} ${SKIPTESTSOPTIONS}
      $pom_modify_script $inputProj/$slug
      if [[ ${slug} = "apache/incubator-dubbo" ]]; then
        if [ ${module} = "dubbo-common" -o ${module} = "dubbo-config/dubbo-config-spring" ]; then
          mvn ekstazi:ekstazi ${PL0} ${MVNOPTIONS}
        else
          mvn ekstazi:ekstazi ${PL} ${MVNOPTIONS}
        fi
      else
        mvn ekstazi:ekstazi ${PL} ${MVNOPTIONS}
      fi

      cd ${inputProj}/${slug}
      git stash
      git checkout -f $secondsha
      mvn clean install ${PL} ${MVNOPTIONS} ${SKIPTESTSOPTIONS}
      $pom_modify_script $inputProj/$slug
      if [[ ${slug} = "apache/incubator-dubbo" ]]; then
        if [ ${module} = "dubbo-common" -o ${module} = "dubbo-config/dubbo-config-spring" ]; then
          mvn ekstazi:ekstazi ${PL0} ${MVNOPTIONS}
        else
          mvn ekstazi:ekstazi ${PL} ${MVNOPTIONS}
        fi
      else
        mvn ekstazi:ekstazi ${PL} ${MVNOPTIONS}
      fi
      mv ${inputProj}/${slug}/${module}/.ekstazi ${inputProj}/${slug}/${module}/.ekstazi-${sec_short_sha}
      cd ${module}
      ls target/surefire-reports/*.xml | cut -d'/' -f3 | sed 's/.xml//g' | sed 's/TEST-//g' > ${inputProj}/${slug}/${module}/.ekstazi-${sec_short_sha}/selected-tests
      rm -rf target
    )
    fi
    firstsha=${secondsha}
  done
done < "$input"
