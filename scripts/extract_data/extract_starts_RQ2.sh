#!/usr/bin/env bash

# The output is like 
# proj, module, test, # total tests of FIC, # total tests of starts (selectMore=true), 
# y/n, # total tests of starts (selectMore=false), y/n, percentage  
# NOTE: This script is used to obtain the evaluation results for RQ2 of IncIDFlakies_S according to the input


if [[ $1 == "" ]]; then
    echo "arg1 - full path to the input file (eg. data/commits.csv)"
    exit
fi

currentDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

input=$1
inputProj=$currentDir"/../../projects"

echo -n "" > $currentDir/../../data/starts_output_RQ2.csv

sum_detection_ground_truth=0
sum_total_tests_of_FIC=0
sum_time_run_iDFlakies=0.00
average_time_run_iDFlakies=0.00
sum_total_tests_of_startsWithReachableStaticFields=0
sum_detect_or_not_startsWithReachableStaticFields=0
sum_ground_truth_startsWithReachableStaticFields=0
sum_percentage_startsWithReachableStaticFields=0.00
sum_time_startsWithReachableStaticFields=0.00
average_percentage_of_time_startsWithReachableStaticFields=0.00
sum_total_tests_of_startsFalse=0
sum_detect_or_not_startsFalse=0
sum_ground_truth_startsFalse=0
sum_percentage_startsFalse=0.00
sum_time_startsFalse=0.00
average_percentage_of_time_startsFalse=0.00
num_of_lines=0

echo "# proj, module, test, # tests selected (normal), % tests selected from normal, ground truth achieved?, empirical achieved?, overall time, analysis time, detection time, % overall time from normal, # tests selected (starts), % tests selected from normal, ground truth achieved?, empirical achieved?, overall time, analysis time, detection time, % overall time from normal, # tests selected (IncIDFlakies_E), % tests selected from normal, ground truth achieved?, empirical achieved?, overall time, analysis time, detection time, % overall time from normal"  >> $currentDir/../../data/starts_output_RQ2.csv
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

	total_tests_of_startsFalse="n/a"
  detect_or_not_startsFalse="N"
  ground_truth_startsFalse="N"
  percentage_startsFalse=0.00
	total_time_startsFalse=0.00
  analysis_time_startsFalse=0.00
  detection_time_startsFalse=0.00
  percentage_of_time_startsFalse=0.00

  total_tests_of_startsWithReachableStaticFields="n/a"
  detect_or_not_startsWithReachableStaticFields="N"
  ground_truth_startsWithReachableStaticFields="N"
  percentage_startsWithReachableStaticFields=0.00
	total_time_startsWithReachableStaticFields=0.00
  analysis_time_startsWithReachableStaticFields=0.00
  detection_time_startsWithReachableStaticFields=0.00
  percentage_of_time_startsWithReachableStaticFields=0.00

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

  if [[ -d ${inputProj}/${slug}/${module}/.dtfixingtools_starts_${fic_short_sha} ]]; then
    selected_tests_FILE=${inputProj}/${slug}/${module}/.dtfixingtools_starts_${fic_short_sha}/selected-tests
    if [[ -f ${selected_tests_FILE} ]]; then
      total_tests_of_startsFalse=$(cat $selected_tests_FILE | grep -c "")
    fi
    FIND_FILE=${inputProj}/${slug}/${module}/.dtfixingtools_starts_${fic_short_sha}/detection-results/list.txt
    if [[ -f ${FIND_FILE} ]]; then
      if [[ `grep -c "${test}" $FIND_FILE` -ne '0' ]];then
        detect_or_not_startsFalse="Y"
      fi
    fi
    if [[ -f $POLLUTER_FILE ]]; then
      if [[ -f $selected_tests_FILE ]]; then
        if [ `grep -c "$test" $selected_tests_FILE` -ne '0' ];then
          while read line
          do 
          if [ `grep -c "$line" $selected_tests_FILE` -ne '0' ];then
              ground_truth_startsFalse="Y"
              break
          fi
          done < $POLLUTER_FILE 
        fi
      fi
    fi
    if [ ${total_tests_of_startsFalse} != "n/a" -a ${total_tests_of_FIC} != "n/a" -a ${total_tests_of_FIC} != "0" ]; then
      percentage_startsFalse=$(echo "scale=2; 100*${total_tests_of_startsFalse}/${total_tests_of_FIC}" | bc -l)
    fi
    timeFILE=${inputProj}/${slug}/${module}/.dtfixingtools_starts_${fic_short_sha}/time
    if [[ -f $timeFILE ]]; then
      analysis_time_startsFalse=`(cut -d',' -f1  ${timeFILE})`
      detection_time_startsFalse=`(cut -d',' -f2  ${timeFILE})`
    fi
    total_time_startsFalse=$(echo "scale=3; ${analysis_time_startsFalse} + ${detection_time_startsFalse}" | bc -l)
    percentage_of_time_startsFalse=$(echo "scale=2; 100*${total_time_startsFalse}/${time_run_iDFlakies}" | bc -l)
    sum_time_startsFalse=$(echo "scale=3; ${total_time_startsFalse} + ${sum_time_startsFalse}" | bc -l)
  fi


  if [[ -d ${inputProj}/${slug}/${module}/.dtfixingtools_starts_plus_${fic_short_sha} ]]; then
    selected_tests_FILE=${inputProj}/${slug}/${module}/.dtfixingtools_starts_plus_${fic_short_sha}/selected-tests
    if [[ -f $selected_tests_FILE ]]; then
      total_tests_of_startsWithReachableStaticFields=$(cat $selected_tests_FILE | grep -c "")
    fi
    FIND_FILE=${inputProj}/${slug}/${module}/.dtfixingtools_starts_plus_${fic_short_sha}/detection-results/list.txt
    if [[ -f $FIND_FILE ]]; then
      if [ `grep -c "$test" $FIND_FILE` -ne '0' ];then
        detect_or_not_startsWithReachableStaticFields="Y"
      fi
    fi
    if [[ -f $POLLUTER_FILE ]]; then
      if [[ -f $selected_tests_FILE ]]; then
        if [ `grep -c "$test" $selected_tests_FILE` -ne '0' ];then
          while read line
          do 
            if [ `grep -c "$line" $selected_tests_FILE` -ne '0' ];then
              ground_truth_startsWithReachableStaticFields="Y"
              break
            fi
          done < $POLLUTER_FILE 
        fi
      fi
    fi
    if [ ${total_tests_of_startsWithReachableStaticFields} != "n/a" -a ${total_tests_of_FIC} != "n/a" -a ${total_tests_of_FIC} != "0" ]; then
      percentage_startsWithReachableStaticFields=$(echo "scale=2; 100*${total_tests_of_startsWithReachableStaticFields}/${total_tests_of_FIC}" | bc -l)
    fi
    timeFILE=${inputProj}/${slug}/${module}/.dtfixingtools_starts_plus_${fic_short_sha}/time
    if [[ -f $timeFILE ]]; then
      analysis_time_startsWithReachableStaticFields=`(cut -d',' -f1  ${timeFILE})`
      detection_time_startsWithReachableStaticFields=`(cut -d',' -f2  ${timeFILE})`
    fi
    total_time_startsWithReachableStaticFields=$(echo "scale=3; ${analysis_time_startsWithReachableStaticFields} + ${detection_time_startsWithReachableStaticFields}" | bc -l)
    percentage_of_time_startsWithReachableStaticFields=$(echo "scale=2; 100*${total_time_startsWithReachableStaticFields}/${time_run_iDFlakies}" | bc -l)
    sum_time_startsWithReachableStaticFields=$(echo "scale=3; ${total_time_startsWithReachableStaticFields} + ${sum_time_startsWithReachableStaticFields}" | bc -l)
  fi


  full_string="$slug,$module,$test,$total_tests_of_FIC,$percentage_normal,$detection_ground_truth,$detect_or_not_normal,$time_run_iDFlakies,$analysis_time_run_iDFlakies,$detection_time_run_iDFlakies,$percentage_of_time_normal,$total_tests_of_startsFalse,$percentage_startsFalse,$ground_truth_startsFalse,$detect_or_not_startsFalse,$total_time_startsFalse,$analysis_time_startsFalse,$detection_time_startsFalse,$percentage_of_time_startsFalse,$total_tests_of_startsWithReachableStaticFields,$percentage_startsWithReachableStaticFields,$ground_truth_startsWithReachableStaticFields,$detect_or_not_startsWithReachableStaticFields,$total_time_startsWithReachableStaticFields,$analysis_time_startsWithReachableStaticFields,$detection_time_startsWithReachableStaticFields,$percentage_of_time_startsWithReachableStaticFields"
  echo $full_string >> $currentDir/../../data/starts_output_RQ2.csv

  if [[ ${total_tests_of_startsFalse} != "n/a" ]]; then
    sum_total_tests_of_FIC=$(echo "${sum_total_tests_of_FIC}+${total_tests_of_FIC}" | bc -l)
    sum_total_tests_of_startsWithReachableStaticFields=$(echo "${sum_total_tests_of_startsWithReachableStaticFields}+${total_tests_of_startsWithReachableStaticFields}" | bc -l)
    if [[ ${detection_ground_truth} = "Y" ]]; then
      sum_detection_ground_truth=$(echo "${sum_detection_ground_truth}+1" | bc -l)
    fi
    if [[ ${detect_or_not_startsWithReachableStaticFields} = "Y" ]]; then
      sum_detect_or_not_startsWithReachableStaticFields=$(echo "${sum_detect_or_not_startsWithReachableStaticFields}+1" | bc -l)
    fi
    if [[ ${ground_truth_startsWithReachableStaticFields} = "Y" ]]; then
      sum_ground_truth_startsWithReachableStaticFields=$(echo "${sum_ground_truth_startsWithReachableStaticFields}+1" | bc -l)
    fi
    if [[ ${total_tests_of_startsFalse} != "n/a" ]]; then
      sum_total_tests_of_startsFalse=$(echo "${sum_total_tests_of_startsFalse}+${total_tests_of_startsFalse}" | bc -l)
    fi
    if [[ ${detect_or_not_startsFalse} = "Y" ]]; then
      sum_detect_or_not_startsFalse=$(echo "${sum_detect_or_not_startsFalse}+1" | bc -l)
    fi
    if [[ ${ground_truth_startsFalse} = "Y" ]]; then
      sum_ground_truth_startsFalse=$(echo "${sum_ground_truth_startsFalse}+1" | bc -l)
    fi
    num_of_lines=$((num_of_lines + 1))
  fi

done < "$input"

average_time_run_iDFlakies=$(echo "scale=4; ${sum_time_run_iDFlakies}/${num_of_lines}" | bc -l)
average_percentage_of_time_startsWithReachableStaticFields=$(echo "scale=2; 100*${sum_time_startsWithReachableStaticFields}/${sum_time_run_iDFlakies}" | bc -l)
average_percentage_of_time_startsFalse=$(echo "scale=2; 100*${sum_time_startsFalse}/${sum_time_run_iDFlakies}" | bc -l)
sum_percentage_startsWithReachableStaticFields=$(echo "scale=2; 100*${sum_total_tests_of_startsWithReachableStaticFields}/${sum_total_tests_of_FIC}" | bc -l)
sum_percentage_startsFalse=$(echo "scale=2; 100*${sum_total_tests_of_startsFalse}/${sum_total_tests_of_FIC}" | bc -l)

sum_full_string="Overall,$num_of_lines,,$sum_total_tests_of_FIC,100.00,$sum_detection_ground_truth,,$average_time_run_iDFlakies,0,$average_time_run_iDFlakies,100.00,$sum_total_tests_of_startsFalse,$sum_percentage_startsFalse,$sum_ground_truth_startsFalse,$sum_detect_or_not_startsFalse,,,,$average_percentage_of_time_startsFalse,$sum_total_tests_of_startsWithReachableStaticFields,$sum_percentage_startsWithReachableStaticFields,$sum_ground_truth_startsWithReachableStaticFields,$sum_detect_or_not_startsWithReachableStaticFields,,,,$average_percentage_of_time_startsWithReachableStaticFields"
echo $sum_full_string >> $currentDir/../../data/starts_output_RQ2.csv
