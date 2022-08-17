#!/usr/bin/env bash

# The output is like 
# proj, module, test, # total tests of FIC, # total tests of ekstazi (selectMore=true), 
# y/n, # total tests of ekstazi (selectMore=false), y/n, percentage  
# NOTE: This script is used to obtain the evaluation results for RQ2 of IncIDFlakies_E according to the input


if [[ $1 == "" ]]; then
    echo "arg1 - full path to the input file (eg. data/commits.csv)"
    exit
fi

currentDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

input=$1
inputProj=$currentDir"/../../projects"

echo -n "" > $currentDir/../../data/ekstazi_output_RQ2.csv

sum_detection_ground_truth=0
sum_total_tests_of_FIC=0
sum_time_run_iDFlakies=0.00
average_time_run_iDFlakies=0.00
sum_total_tests_of_ekstaziWithReachableStaticFields=0
sum_detect_or_not_ekstaziWithReachableStaticFields=0
sum_ground_truth_ekstaziWithReachableStaticFields=0
sum_percentage_ekstaziWithReachableStaticFields=0.00
sum_time_ekstaziWithReachableStaticFields=0.00
average_percentage_of_time_ekstaziWithReachableStaticFields=0.00
sum_total_tests_of_ekstaziFalse=0
sum_detect_or_not_ekstaziFalse=0
sum_ground_truth_ekstaziFalse=0
sum_percentage_ekstaziFalse=0.00
sum_time_ekstaziFalse=0.00
average_percentage_of_time_ekstaziFalse=0.00
num_of_lines=0

echo "# proj, module, test, # tests selected (normal), % tests selected from normal, ground truth achieved?, empirical achieved?, overall time, analysis time, detection time, % overall time from normal, # tests selected (ekstazi), % tests selected from normal, ground truth achieved?, empirical achieved?, overall time, analysis time, detection time, % overall time from normal, # tests selected (IncIDFlakies_E), % tests selected from normal, ground truth achieved?, empirical achieved?, overall time, analysis time, detection time, % overall time from normal"  >> $currentDir/../../data/ekstazi_output_RQ2.csv
while IFS= read -r line
do
  if [[ ${line} =~ ^\# ]]; then 
    continue
  fi

  slug=$(echo $line | cut -d',' -f1)
  module=$(echo $line | cut -d',' -f2)
  test=$(echo $line | cut -d',' -f3)
  fic_sha=$(echo $line | cut -d',' -f4)
  initial_sha_in_csv=$(echo $line | cut -d',' -f5)
  
  fic_short_sha=${fic_sha: 0: 7}

  total_tests_of_FIC="n/a"
	detect_or_not_normal="N"
	detection_ground_truth="N"
	percentage_normal=100.00
  time_run_iDFlakies=0.00
	analysis_time_run_iDFlakies=0.00
	detection_time_run_iDFlakies=0.00
	percentage_of_time_normal=100.00

	total_tests_of_ekstaziFalse="n/a"
  detect_or_not_ekstaziFalse="N"
  ground_truth_ekstaziFalse="N"
  percentage_ekstaziFalse=0.00
	total_time_ekstaziFalse=0.00
  analysis_time_ekstaziFalse=0.00
  detection_time_ekstaziFalse=0.00
  percentage_of_time_ekstaziFalse=0.00

  total_tests_of_ekstaziWithReachableStaticFields="n/a"
  detect_or_not_ekstaziWithReachableStaticFields="N"
  ground_truth_ekstaziWithReachableStaticFields="N"
  percentage_ekstaziWithReachableStaticFields=0.00
	total_time_ekstaziWithReachableStaticFields=0.00
  analysis_time_ekstaziWithReachableStaticFields=0.00
  detection_time_ekstaziWithReachableStaticFields=0.00
  percentage_of_time_ekstaziWithReachableStaticFields=0.00

  POLLUTER_FILE=${currentDir}/../../polluters/${test}-${fic_short_sha}.txt

  if [[ -d ${inputProj}/${slug}/${module}/.dtfixingtools_baseline_${fic_short_sha} ]]; then
    time_run_iDFlakies=0.00
    original_order_FILE=${inputProj}/${slug}/${module}/.dtfixingtools_baseline_${fic_short_sha}/original-order
    if [[ -f $original_order_FILE ]]; then
      total_tests_of_FIC=$(cat $original_order_FILE | grep -c "")
    fi
    if [[ -f $POLLUTER_FILE ]]; then      
      if [[ -f $original_order_FILE ]]; then
        while read line
        do 
          if [ `grep -c "$line" $original_order_FILE` -ne '0' ];then
            detection_ground_truth="Y"
            break
          fi
        done < $POLLUTER_FILE 
      fi
    fi
		FIND_FILE=${inputProj}/${slug}/${module}/.dtfixingtools_baseline_${fic_short_sha}/detection-results/list.txt
    if [[ -f ${FIND_FILE} ]]; then
      if [[ `grep -c "${test}" $FIND_FILE` -ne '0' ]];then
        detect_or_not_normal="Y"
      fi
    fi
    timeFILE=${inputProj}/${slug}/${module}/.dtfixingtools_baseline_${fic_short_sha}/time
    if [[ -f $timeFILE ]]; then
      time_run_iDFlakies=`(cut -d',' -f1  ${timeFILE})`
			detection_time_run_iDFlakies=${time_run_iDFlakies}
      sum_time_run_iDFlakies=$(echo "scale=3; ${time_run_iDFlakies} + ${sum_time_run_iDFlakies}" | bc -l)
    fi
  fi

  if [[ -d ${inputProj}/${slug}/${module}/.dtfixingtools_eks_${fic_short_sha} ]]; then
    selected_tests_FILE=${inputProj}/${slug}/${module}/.dtfixingtools_eks_${fic_short_sha}/selected-tests
    if [[ -f ${selected_tests_FILE} ]]; then
      total_tests_of_ekstaziFalse=$(cat $selected_tests_FILE | grep -c "")
    fi
    FIND_FILE=${inputProj}/${slug}/${module}/.dtfixingtools_eks_${fic_short_sha}/detection-results/list.txt
    if [[ -f ${FIND_FILE} ]]; then
      if [[ `grep -c "${test}" $FIND_FILE` -ne '0' ]];then
        detect_or_not_ekstaziFalse="Y"
      fi
    fi
    if [[ -f $POLLUTER_FILE ]]; then
      if [[ -f $selected_tests_FILE ]]; then
        if [ `grep -c "$test" $selected_tests_FILE` -ne '0' ];then
          while read line
          do 
          if [ `grep -c "$line" $selected_tests_FILE` -ne '0' ];then
              ground_truth_ekstaziFalse="Y"
              break
          fi
          done < $POLLUTER_FILE 
        fi
      fi
    fi
    if [ ${total_tests_of_ekstaziFalse} != "n/a" -a ${total_tests_of_FIC} != "n/a" -a ${total_tests_of_FIC} != "0" ]; then
      percentage_ekstaziFalse=$(echo "scale=2; 100*${total_tests_of_ekstaziFalse}/${total_tests_of_FIC}" | bc -l)
    fi
    timeFILE=${inputProj}/${slug}/${module}/.dtfixingtools_eks_${fic_short_sha}/time
    if [[ -f $timeFILE ]]; then
      analysis_time_ekstaziFalse=`(cut -d',' -f1  ${timeFILE})`
      detection_time_ekstaziFalse=`(cut -d',' -f2  ${timeFILE})`
    fi
    total_time_ekstaziFalse=$(echo "scale=3; ${analysis_time_ekstaziFalse} + ${detection_time_ekstaziFalse}" | bc -l)
    percentage_of_time_ekstaziFalse=$(echo "scale=2; 100*${total_time_ekstaziFalse}/${time_run_iDFlakies}" | bc -l)
    sum_time_ekstaziFalse=$(echo "scale=3; ${total_time_ekstaziFalse} + ${sum_time_ekstaziFalse}" | bc -l)
  fi


  if [[ -d ${inputProj}/${slug}/${module}/.dtfixingtools_eks_plus_${fic_short_sha} ]]; then
    selected_tests_FILE=${inputProj}/${slug}/${module}/.dtfixingtools_eks_plus_${fic_short_sha}/selected-tests
    if [[ -f $selected_tests_FILE ]]; then
      total_tests_of_ekstaziWithReachableStaticFields=$(cat $selected_tests_FILE | grep -c "")
    fi
    FIND_FILE=${inputProj}/${slug}/${module}/.dtfixingtools_eks_plus_${fic_short_sha}/detection-results/list.txt
    if [[ -f $FIND_FILE ]]; then
      if [ `grep -c "$test" $FIND_FILE` -ne '0' ];then
        detect_or_not_ekstaziWithReachableStaticFields="Y"
      fi
    fi
    if [[ -f $POLLUTER_FILE ]]; then
      if [[ -f $selected_tests_FILE ]]; then
        if [ `grep -c "$test" $selected_tests_FILE` -ne '0' ];then
          while read line
          do 
            if [ `grep -c "$line" $selected_tests_FILE` -ne '0' ];then
              ground_truth_ekstaziWithReachableStaticFields="Y"
              break
            fi
          done < $POLLUTER_FILE 
        fi
      fi
    fi
    if [ ${total_tests_of_ekstaziWithReachableStaticFields} != "n/a" -a ${total_tests_of_FIC} != "n/a" -a ${total_tests_of_FIC} != "0" ]; then
      percentage_ekstaziWithReachableStaticFields=$(echo "scale=2; 100*${total_tests_of_ekstaziWithReachableStaticFields}/${total_tests_of_FIC}" | bc -l)
    fi
    timeFILE=${inputProj}/${slug}/${module}/.dtfixingtools_eks_plus_${fic_short_sha}/time
    if [[ -f $timeFILE ]]; then
      analysis_time_ekstaziWithReachableStaticFields=`(cut -d',' -f1  ${timeFILE})`
      detection_time_ekstaziWithReachableStaticFields=`(cut -d',' -f2  ${timeFILE})`
    fi
    total_time_ekstaziWithReachableStaticFields=$(echo "scale=3; ${analysis_time_ekstaziWithReachableStaticFields} + ${detection_time_ekstaziWithReachableStaticFields}" | bc -l)
    percentage_of_time_ekstaziWithReachableStaticFields=$(echo "scale=2; 100*${total_time_ekstaziWithReachableStaticFields}/${time_run_iDFlakies}" | bc -l)
    sum_time_ekstaziWithReachableStaticFields=$(echo "scale=3; ${total_time_ekstaziWithReachableStaticFields} + ${sum_time_ekstaziWithReachableStaticFields}" | bc -l)
  fi


  full_string="$slug,$module,$test,$total_tests_of_FIC,$percentage_normal,$detection_ground_truth,$detect_or_not_normal,$time_run_iDFlakies,$analysis_time_run_iDFlakies,$detection_time_run_iDFlakies,$percentage_of_time_normal,$total_tests_of_ekstaziFalse,$percentage_ekstaziFalse,$ground_truth_ekstaziFalse,$detect_or_not_ekstaziFalse,$total_time_ekstaziFalse,$analysis_time_ekstaziFalse,$detection_time_ekstaziFalse,$percentage_of_time_ekstaziFalse,$total_tests_of_ekstaziWithReachableStaticFields,$percentage_ekstaziWithReachableStaticFields,$ground_truth_ekstaziWithReachableStaticFields,$detect_or_not_ekstaziWithReachableStaticFields,$total_time_ekstaziWithReachableStaticFields,$analysis_time_ekstaziWithReachableStaticFields,$detection_time_ekstaziWithReachableStaticFields,$percentage_of_time_ekstaziWithReachableStaticFields"
  echo $full_string >> $currentDir/../../data/ekstazi_output_RQ2.csv

  if [[ ${total_tests_of_ekstaziFalse} != "n/a" ]]; then
    sum_total_tests_of_FIC=$(echo "${sum_total_tests_of_FIC}+${total_tests_of_FIC}" | bc -l)
    sum_total_tests_of_ekstaziWithReachableStaticFields=$(echo "${sum_total_tests_of_ekstaziWithReachableStaticFields}+${total_tests_of_ekstaziWithReachableStaticFields}" | bc -l)
    if [[ ${detection_ground_truth} = "Y" ]]; then
      sum_detection_ground_truth=$(echo "${sum_detection_ground_truth}+1" | bc -l)
    fi
    if [[ ${detect_or_not_ekstaziWithReachableStaticFields} = "Y" ]]; then
      sum_detect_or_not_ekstaziWithReachableStaticFields=$(echo "${sum_detect_or_not_ekstaziWithReachableStaticFields}+1" | bc -l)
    fi
    if [[ ${ground_truth_ekstaziWithReachableStaticFields} = "Y" ]]; then
      sum_ground_truth_ekstaziWithReachableStaticFields=$(echo "${sum_ground_truth_ekstaziWithReachableStaticFields}+1" | bc -l)
    fi
    if [[ ${total_tests_of_ekstaziFalse} != "n/a" ]]; then
      sum_total_tests_of_ekstaziFalse=$(echo "${sum_total_tests_of_ekstaziFalse}+${total_tests_of_ekstaziFalse}" | bc -l)
    fi
    if [[ ${detect_or_not_ekstaziFalse} = "Y" ]]; then
      sum_detect_or_not_ekstaziFalse=$(echo "${sum_detect_or_not_ekstaziFalse}+1" | bc -l)
    fi
    if [[ ${ground_truth_ekstaziFalse} = "Y" ]]; then
      sum_ground_truth_ekstaziFalse=$(echo "${sum_ground_truth_ekstaziFalse}+1" | bc -l)
    fi
    num_of_lines=$((num_of_lines + 1))
  fi

done < "$input"

average_time_run_iDFlakies=$(echo "scale=4; ${sum_time_run_iDFlakies}/${num_of_lines}" | bc -l)
average_percentage_of_time_ekstaziWithReachableStaticFields=$(echo "scale=2; 100*${sum_time_ekstaziWithReachableStaticFields}/${sum_time_run_iDFlakies}" | bc -l)
average_percentage_of_time_ekstaziFalse=$(echo "scale=2; 100*${sum_time_ekstaziFalse}/${sum_time_run_iDFlakies}" | bc -l)
sum_percentage_ekstaziWithReachableStaticFields=$(echo "scale=2; 100*${sum_total_tests_of_ekstaziWithReachableStaticFields}/${sum_total_tests_of_FIC}" | bc -l)
sum_percentage_ekstaziFalse=$(echo "scale=2; 100*${sum_total_tests_of_ekstaziFalse}/${sum_total_tests_of_FIC}" | bc -l)

sum_full_string="Overall,$num_of_lines,,$sum_total_tests_of_FIC,100.00,$sum_detection_ground_truth,,$average_time_run_iDFlakies,0,$average_time_run_iDFlakies,100.00,$sum_total_tests_of_ekstaziFalse,$sum_percentage_ekstaziFalse,$sum_ground_truth_ekstaziFalse,$sum_detect_or_not_ekstaziFalse,,,,$average_percentage_of_time_ekstaziFalse,$sum_total_tests_of_ekstaziWithReachableStaticFields,$sum_percentage_ekstaziWithReachableStaticFields,$sum_ground_truth_ekstaziWithReachableStaticFields,$sum_detect_or_not_ekstaziWithReachableStaticFields,,,,$average_percentage_of_time_ekstaziWithReachableStaticFields"
echo $sum_full_string >> $currentDir/../../data/ekstazi_output_RQ2.csv
