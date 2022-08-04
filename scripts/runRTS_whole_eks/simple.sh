#!/usr/bin/env bash

# This script is to only run iDFlakies using tests selected by ekstazi

# find . -d -name ".dtfixingtools*" | xargs rm -rf # remove all the dirty info

if [[ $1 == "" ]] ; then
    echo "arg1 - full path to the test file (eg. data/commits.csv)"
    echo "This script is to only run iDFlakies using tests selected by ekstazi"
    exit
fi

currentDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

input=$1
inputProj=$currentDir"/../../projects"

inc_pom_modify_script=$currentDir/../inc-pom-modify/modify-project.sh

ekstaziSelectedTestsDirPrefix=$currentDir"/../../data/ekstazi-selected-tests"
ekstaziDependenciesDirPrefix=$currentDir"/../../data/ekstazi-dependencies"

IDFLAKIESOPTIONS="-Ddt.detector.roundsemantics.total=true -Ddetector.detector_type=random-class-method -Ddt.randomize.rounds=10 -Ddt.detector.original_order.all_must_pass=false -Ddt.verify.rounds=0"
MVNOPTIONS="-Ddependency-check.skip=true -Denforcer.skip=true -Drat.skip=true -Dmdep.analyze.skip=true -Dmaven.javadoc.skip=true -Dgpg.skip -Dlicense.skip=true -Dcheckstyle.skip=true"
SKIPTESTSOPTIONS="-DskipTests=true"

SELECTMOREOPTION="-Ddt.incdetector.selectmore=true"
NOTSELECTMOREOPTION="-Ddt.incdetector.selectmore=false"

# the following options are for soot analysis
# SELECTONMETHODOPTION="-Ddt.incdetector.selectonmethods=true"
# SELECTONMETHODUPGRADEOPTION="-Ddt.incdetector.selectonmethodsupgrade=true"

DONOTDETECT="-Ddt.incdetector.detectornot=false"

EKSTAZIOPTION="-Ddt.incdetector.ekstazi=true"

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
    
    ekstaziSelectedTestsDir=${ekstaziSelectedTestsDirPrefix}/${slug}/${module}/${sec_short_sha}
    ekstaziDependenciesDir=${ekstaziDependenciesDirPrefix}/${slug}/${module}/${sec_short_sha}
    EKSTAZISELECTEDTESTS="-Ddt.incdetector.ekstaziselectedtests=${ekstaziSelectedTestsDir}/selected-tests"
    EKSTAZIDEPENDENCIES="-Ddt.incdetector.ekstazidependencies=${ekstaziDependenciesDir}/dependencies"

    if [[ ! -d ${inputProj}/${slug}/${module}/.dtfixingtools_eks_${sec_short_sha} ]]; then
      (
        rm -rf ${inputProj}/${slug}/${module}/.dtfixingtools
        cd ${inputProj}/${slug}
        git checkout -f $firstsha
        mvn clean install ${PL} ${MVNOPTIONS} ${SKIPTESTSOPTIONS}
        $inc_pom_modify_script $inputProj/$slug
        # The module dubbo-cluster in project apache/incubator-dubbo can not be built using ${PL0}
        if [[ ${slug} = "apache/incubator-dubbo" ]]; then
          if [[ ${module} != "dubbo-cluster" ]]; then
            mvn testrunner:testplugin ${PL0} ${MVNOPTIONS} ${IDFLAKIESOPTIONS} ${NOTSELECTMOREOPTION} ${DONOTDETECT} ${EKSTAZIOPTION}
          else
            mvn testrunner:testplugin ${PL} ${MVNOPTIONS} ${IDFLAKIESOPTIONS} ${NOTSELECTMOREOPTION} ${DONOTDETECT} ${EKSTAZIOPTION}
          fi
        else
          mvn testrunner:testplugin ${PL} ${MVNOPTIONS} ${IDFLAKIESOPTIONS} ${NOTSELECTMOREOPTION} ${DONOTDETECT} ${EKSTAZIOPTION}
        fi

        cd ${inputProj}/${slug}
        git checkout -f $secondsha
        mvn clean install ${PL} ${MVNOPTIONS} ${SKIPTESTSOPTIONS}
        $inc_pom_modify_script $inputProj/$slug
        if [[ ${slug} = "apache/incubator-dubbo" ]]; then
          if [[ ${module} != "dubbo-cluster" ]]; then
            mvn testrunner:testplugin ${PL0} ${MVNOPTIONS} ${IDFLAKIESOPTIONS} ${NOTSELECTMOREOPTION} ${EKSTAZIOPTION} ${EKSTAZISELECTEDTESTS} ${EKSTAZIDEPENDENCIES}
          else
            mvn testrunner:testplugin ${PL} ${MVNOPTIONS} ${IDFLAKIESOPTIONS} ${NOTSELECTMOREOPTION} ${EKSTAZIOPTION} ${EKSTAZISELECTEDTESTS} ${EKSTAZIDEPENDENCIES}
          fi
        else
          mvn testrunner:testplugin ${PL} ${MVNOPTIONS} ${IDFLAKIESOPTIONS} ${NOTSELECTMOREOPTION} ${EKSTAZIOPTION} ${EKSTAZISELECTEDTESTS} ${EKSTAZIDEPENDENCIES}
        fi
        mv $module/.dtfixingtools $module/.dtfixingtools_eks_${sec_short_sha}
      )
    fi
    firstsha=${secondsha}
  done
done < "$input"
