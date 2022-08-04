#!/usr/bin/env bash

# This script is used to run iDFlakies only using tests selected by STARTs

# find . -d -name ".dtfixingtools*" | xargs rm -rf # remove all the dirty info

if [[ $1 == "" ]] ; then
    echo "arg1 - full path to the test file (eg. data/commits.csv)"
    echo "This script is used to run iDFlakies only using tests selected by STARTs"
    exit
fi

currentDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

input=$1
inputProj=$currentDir"/../../projects"

inc_pom_modify_script=$currentDir/../inc-pom-modify/modify-project.sh

startsSelectedTestsDirPrefix=$currentDir"/../../data/starts-selected-tests"
startsDependenciesDirPrefix=$currentDir"/../../data/starts-dependencies"

IDFLAKIESOPTIONS="-Ddt.detector.roundsemantics.total=true -Ddetector.detector_type=random-class-method -Ddt.randomize.rounds=10 -Ddt.detector.original_order.all_must_pass=false -Ddt.verify.rounds=0"
MVNOPTIONS="-Ddependency-check.skip=true -Denforcer.skip=true -Drat.skip=true -Dmdep.analyze.skip=true -Dmaven.javadoc.skip=true -Dgpg.skip -Dlicense.skip=true -Dcheckstyle.skip=true"
SKIPTESTSOPTIONS="-DskipTests=true"

SELECTMOREOPTION="-Ddt.incdetector.selectmore=true"
NOTSELECTMOREOPTION="-Ddt.incdetector.selectmore=false"

# the following options are for soot analysis
# SELECTONMETHODOPTION="-Ddt.incdetector.selectonmethods=true"
# SELECTONMETHODUPGRADEOPTION="-Ddt.incdetector.selectonmethodsupgrade=true"

DONOTDETECT="-Ddt.incdetector.detectornot=false"

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
    
    startsSelectedTestsDir=${startsSelectedTestsDirPrefix}/${slug}/${module}/${sec_short_sha}
    startsDependenciesDir=${startsDependenciesDirPrefix}/${slug}/${module}/${sec_short_sha}
    STARTSSELECTEDTESTS="-Ddt.incdetector.startsselectedtests=${startsSelectedTestsDir}/selected-tests"
    STARTSDEPENDENCIES="-Ddt.incdetector.startsdependencies=${startsDependenciesDir}/dependencies"

    if [[ ! -d ${inputProj}/${slug}/${module}/.dtfixingtools_starts_${sec_short_sha} ]]; then
      (
        rm -rf ${inputProj}/${slug}/${module}/.dtfixingtools

        cd ${inputProj}/${slug}
        git checkout -f $secondsha
        mvn clean install ${PL} ${MVNOPTIONS} ${SKIPTESTSOPTIONS}
        $inc_pom_modify_script $inputProj/$slug
        if [[ ${slug} = "apache/incubator-dubbo" ]]; then
          if [ ${module} = "dubbo-common" -o ${module} = "dubbo-config/dubbo-config-spring" ]; then
            mvn testrunner:testplugin ${PL0} ${MVNOPTIONS} ${IDFLAKIESOPTIONS} ${NOTSELECTMOREOPTION} ${STARTSSELECTEDTESTS} ${STARTSDEPENDENCIES}
          else
            mvn testrunner:testplugin ${PL} ${MVNOPTIONS} ${IDFLAKIESOPTIONS} ${NOTSELECTMOREOPTION} ${STARTSSELECTEDTESTS} ${STARTSDEPENDENCIES}
          fi
        else
          mvn testrunner:testplugin ${PL} ${MVNOPTIONS} ${IDFLAKIESOPTIONS} ${NOTSELECTMOREOPTION} ${STARTSSELECTEDTESTS} ${STARTSDEPENDENCIES}
        fi
        mv $module/.dtfixingtools $module/.dtfixingtools_starts_${sec_short_sha}
      )
    fi
    firstsha=${secondsha}
  done
done < "$input"
