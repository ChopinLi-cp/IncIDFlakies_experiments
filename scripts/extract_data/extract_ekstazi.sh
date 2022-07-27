#!/usr/bin/env bash

# The output is like 
# proj, module, test, # total tests of FIC, # total tests of ekstazi (selectMore=true), 
# y/n, # total tests of ekstazi (selectMore=false), y/n, percentage  
# NOTE: This script is used to extract the information according to the input


if [[ $1 == "" ]]; then
    echo "arg1 - full path to the input file (eg. input.csv)"
    exit
fi

currentDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

input=$1
inputProj=$currentDir"/../../projects"

cut -d',' -f1,2,4- ${input} | sort -u > tmp.csv

echo -n "" > $currentDir/../../data/ekstazi_output_full.csv

sum_total_tests_of_normal=0
sum_total_time_run_iDFlakies=0.00
average_time_run_iDFlakies=0.00
ant_total_select_tests_normal=0
ant_avg_select_tests_normal=0
sum_percentage_of_test_ekstaziWithReachableStaticFields=0.00
sum_percentage_of_time_ekstaziWithReachableStaticFields=0.00
sum_total_tests_of_ekstaziWithReachableStaticFields=0
sum_percentage_ekstaziWithReachableStaticFields=0.00
sum_total_time_ekstaziWithReachableStaticFields=0.00
average_percentage_of_time_ekstaziWithReachableStaticFields=0.00
ant_total_select_tests_ekstaziWithReachableStaticFields=0
ant_avg_select_tests_ekstaziWithReachableStaticFields=0
sum_percentage_of_test_ekstaziFalse=0.00
sum_percentage_of_time_ekstaziFalse=0.00
sum_total_tests_of_ekstaziFalse=0
sum_percentage_ekstaziFalse=0.00
sum_total_time_ekstaziFalse=0.00
average_percentage_of_time_ekstaziFalse=0.00
ant_total_select_tests_ekstaziFalse=0
ant_avg_select_tests_ekstaziFalse=0
num_of_lines=0
whole_divisor=0

echo "# proj, module, fic_sha, # tests selected (normal), % tests selected from normal, overall time, analysis time, detection time, % overall time from normal, # tests selected (ekstazi), % tests selected from normal, overall time, analysis time, detection time, % overall time from normal, # tests selected (ekstazi+reachableStaticFields), % tests selected from normal, overall time, analysis time, detection time, % overall time from normal"  >> $currentDir/../../data/ekstazi_output_full.csv
while IFS= read -r line
do
  if [[ ${line} =~ ^\# ]]; then 
    continue
  fi

  slug=$(echo $line | cut -d',' -f1)
  module=$(echo $line | cut -d',' -f2)
  fic_sha=$(echo $line | cut -d',' -f3)

  fic_short_sha=${fic_sha: 0: 7}

  total_tests_of_normal=0
  avg_tests_of_normal=0
  percentage_normal=100.00
  time_run_iDFlakies=0.00
  avg_time_run_iDFlakies=0.00
  analysis_time_run_iDFlakies=0.00
  avg_analysis_time_run_iDFlakies=0.00
  detection_time_run_iDFlakies=0.00
  avg_detection_time_run_iDFlakies=0.00
  percentage_of_time_normal=100.00

  total_tests_of_ekstaziFalse=0
  avg_tests_of_ekstaziFalse=0
  percentage_ekstaziFalse=0.00
  total_time_ekstaziFalse=0.00
  avg_total_time_ekstaziFalse=0.00
  total_analysis_time_ekstaziFalse=0.00
  analysis_time_ekstaziFalse=0.00
  avg_analysis_time_ekstaziFalse=0.00
  detection_time_ekstaziFalse=0.00
  avg_detection_time_ekstaziFalse=0.00
  total_detection_time_ekstaziFalse=0.00
  percentage_of_time_ekstaziFalse=0.00

  total_tests_of_ekstaziWithReachableStaticFields=0
  avg_total_tests_of_ekstaziWithReachableStaticFields=0
  percentage_ekstaziWithReachableStaticFields=0.00
  total_time_ekstaziWithReachableStaticFields=0.00
  avg_total_time_ekstaziWithReachableStaticFields=0.00
  total_analysis_time_ekstaziWithReachableStaticFields=0.00
  analysis_time_ekstaziWithReachableStaticFields=0.00
  avg_analysis_time_ekstaziWithReachableStaticFields=0.00
  total_detection_time_ekstaziWithReachableStaticFields=0.00
  detection_time_ekstaziWithReachableStaticFields=0.00
  avg_detection_time_ekstaziWithReachableStaticFields=0.00
  percentage_of_time_ekstaziWithReachableStaticFields=0.00
  
  divisor=0
  for secondsha in $(echo ${line} | cut -d',' -f3-8 | sed 's;,; ;g');
  do 
    nextsha=${secondsha: 0: 7}
    if [[ -d ${inputProj}/${slug}/${module}/.dtfixingtools_baseline_${nextsha} ]]; then
      original_order_FILE=${inputProj}/${slug}/${module}/.dtfixingtools_baseline_${nextsha}/original-order
      if [[ -f $original_order_FILE ]]; then
        total_tests_of_normal_b=$(cat $original_order_FILE | grep -c "")
        total_tests_of_normal=$(echo "${total_tests_of_normal} + ${total_tests_of_normal_b}" | bc -l)
      fi
      timeFILE=${inputProj}/${slug}/${module}/.dtfixingtools_baseline_${nextsha}/time
      if [[ -f $timeFILE ]]; then
        time_run_iDFlakies_b=$(cut -d',' -f1  ${timeFILE})
        time_run_iDFlakies=$(echo "${time_run_iDFlakies} + ${time_run_iDFlakies_b}" | bc -l)
        detection_time_run_iDFlakies=${time_run_iDFlakies}
      fi

      if [[ -d ${inputProj}/${slug}/${module}/.dtfixingtools_eks_${nextsha} ]]; then
        selected_tests_FILE=${inputProj}/${slug}/${module}/.dtfixingtools_eks_${nextsha}/selected-tests
        if [[ -f ${selected_tests_FILE} ]]; then
          total_tests_of_ekstaziFalse_b=$(cat $selected_tests_FILE | grep -c "")
          total_tests_of_ekstaziFalse=$(echo "${total_tests_of_ekstaziFalse} + ${total_tests_of_ekstaziFalse_b}" | bc -l)
          ekstaziFalse_selected_tests_percent_b=$(echo "100*${total_tests_of_ekstaziFalse_b}/${total_tests_of_normal_b}" | bc -l)
          sum_percentage_of_test_ekstaziFalse=$(echo "${sum_percentage_of_test_ekstaziFalse} + ${ekstaziFalse_selected_tests_percent_b}" | bc -l)
        fi
        timeFILE=${inputProj}/${slug}/${module}/.dtfixingtools_eks_${nextsha}/time
        if [[ -f $timeFILE ]]; then
          analysis_time_ekstaziFalse=$(cut -d',' -f1  ${timeFILE})
          total_analysis_time_ekstaziFalse=$(echo "${total_analysis_time_ekstaziFalse} + ${analysis_time_ekstaziFalse}" | bc -l)
          detection_time_ekstaziFalse=$(cut -d',' -f2  ${timeFILE})
          total_detection_time_ekstaziFalse=$(echo "${total_detection_time_ekstaziFalse} + ${detection_time_ekstaziFalse}" | bc -l)
        fi
        total_time_ekstaziFalse_b=$(echo "${analysis_time_ekstaziFalse} + ${detection_time_ekstaziFalse}" | bc -l)
        total_time_ekstaziFalse=$(echo "${total_time_ekstaziFalse} + ${total_time_ekstaziFalse_b}" | bc -l)
        percentage_of_time_ekstaziFalse_b=$(echo "100*${total_time_ekstaziFalse_b}/${time_run_iDFlakies_b}" | bc -l)
        sum_percentage_of_time_ekstaziFalse=$(echo "${sum_percentage_of_time_ekstaziFalse} + ${percentage_of_time_ekstaziFalse_b}" | bc -l)
      fi

      if [[ -d ${inputProj}/${slug}/${module}/.dtfixingtools_eks_plus_${nextsha} ]]; then
        selected_tests_FILE=${inputProj}/${slug}/${module}/.dtfixingtools_eks_plus_${nextsha}/selected-tests
        if [[ -f $selected_tests_FILE ]]; then
          total_tests_of_ekstaziWithReachableStaticFields_b=$(cat $selected_tests_FILE | grep -c "")
          total_tests_of_ekstaziWithReachableStaticFields=$(echo "${total_tests_of_ekstaziWithReachableStaticFields} + ${total_tests_of_ekstaziWithReachableStaticFields_b}" | bc -l)
          percentage_ekstaziWithReachableStaticFields_b=$(echo "100*${total_tests_of_ekstaziWithReachableStaticFields_b}/${total_tests_of_normal_b}" | bc -l)
          sum_percentage_of_test_ekstaziWithReachableStaticFields=$(echo "${sum_percentage_of_test_ekstaziWithReachableStaticFields} + ${percentage_ekstaziWithReachableStaticFields_b}" | bc -l)
        fi
        timeFILE=${inputProj}/${slug}/${module}/.dtfixingtools_eks_plus_${nextsha}/time
        if [[ -f $timeFILE ]]; then
          analysis_time_ekstaziWithReachableStaticFields=$(cut -d',' -f1  ${timeFILE})
          total_analysis_time_ekstaziWithReachableStaticFields=$(echo "${total_analysis_time_ekstaziWithReachableStaticFields} + ${analysis_time_ekstaziWithReachableStaticFields}" | bc -l)
          detection_time_ekstaziWithReachableStaticFields=$(cut -d',' -f2  ${timeFILE})
          total_detection_time_ekstaziWithReachableStaticFields=$(echo "${total_detection_time_ekstaziWithReachableStaticFields} + ${detection_time_ekstaziWithReachableStaticFields}" | bc -l)
        fi
        total_time_ekstaziWithReachableStaticFields_b=$(echo "${analysis_time_ekstaziWithReachableStaticFields} + ${detection_time_ekstaziWithReachableStaticFields}" | bc -l)
        total_time_ekstaziWithReachableStaticFields=$(echo "${total_time_ekstaziWithReachableStaticFields} + ${total_time_ekstaziWithReachableStaticFields_b}" | bc -l)
        percentage_of_time_ekstaziWithReachableStaticFields_b=$(echo "100*${total_time_ekstaziWithReachableStaticFields_b}/${time_run_iDFlakies_b}" | bc -l)
        sum_percentage_of_time_ekstaziWithReachableStaticFields=$(echo "${sum_percentage_of_time_ekstaziWithReachableStaticFields} + ${percentage_of_time_ekstaziWithReachableStaticFields_b}" | bc -l)
      fi
      divisor=$(echo "${divisor} + 1" | bc -l)
      whole_divisor=$(echo "${whole_divisor} + 1" | bc -l)
    fi
  done

  # if [[ $slug = "ctco/cukes" ]]; then
  #   divisor=4
  # else 
  #   divisor=5
  # fi

  avg_tests_of_normal=$(echo "${total_tests_of_normal} / ${divisor}" | bc -l)
  avg_time_run_iDFlakies=$(echo "${time_run_iDFlakies} / ${divisor}" | bc -l)
  avg_tests_of_ekstaziFalse=$(echo "${total_tests_of_ekstaziFalse} / ${divisor}" | bc -l)
  avg_total_time_ekstaziFalse=$(echo "${total_time_ekstaziFalse} / ${divisor}" | bc -l)
  avg_analysis_time_ekstaziFalse=$(echo "${total_analysis_time_ekstaziFalse} / ${divisor}" | bc -l)
  avg_detection_time_ekstaziFalse=$(echo "${total_detection_time_ekstaziFalse} / ${divisor}" | bc -l)
  avg_tests_of_ekstaziWithReachableStaticFields=$(echo "${total_tests_of_ekstaziWithReachableStaticFields} / ${divisor}" | bc -l)
  avg_total_time_ekstaziWithReachableStaticFields=$(echo "${total_time_ekstaziWithReachableStaticFields} / ${divisor}" | bc -l)
  avg_analysis_time_ekstaziWithReachableStaticFields=$(echo "${total_analysis_time_ekstaziWithReachableStaticFields} / ${divisor}" | bc -l)
  avg_detection_time_ekstaziWithReachableStaticFields=$(echo "${total_detection_time_ekstaziWithReachableStaticFields} / ${divisor}" | bc -l)

  sum_total_time_run_iDFlakies=$(echo "${sum_total_time_run_iDFlakies} + ${time_run_iDFlakies}" | bc -l)
  sum_total_time_ekstaziFalse=$(echo "${sum_total_time_ekstaziFalse} + ${total_time_ekstaziFalse}" | bc -l)
  sum_total_time_ekstaziWithReachableStaticFields=$(echo "${sum_total_time_ekstaziWithReachableStaticFields} + ${total_time_ekstaziWithReachableStaticFields}" | bc -l)
  
  avg_detection_time_run_iDFlakies=${avg_time_run_iDFlakies}

  percentage_ekstaziFalse=$(echo "100*${total_tests_of_ekstaziFalse}/${total_tests_of_normal}" | bc -l)
  percentage_of_time_ekstaziFalse=$(echo "100*${total_time_ekstaziFalse}/${time_run_iDFlakies}" | bc -l) 
  percentage_ekstaziWithReachableStaticFields=$(echo "100*${total_tests_of_ekstaziWithReachableStaticFields}/${total_tests_of_normal}" | bc -l)
  percentage_of_time_ekstaziWithReachableStaticFields=$(echo "100*${total_time_ekstaziWithReachableStaticFields}/${time_run_iDFlakies}" | bc -l)
  full_string="$slug,$module,$fic_short_sha,$avg_tests_of_normal,$percentage_normal,$avg_time_run_iDFlakies,$avg_analysis_time_run_iDFlakies,$avg_detection_time_run_iDFlakies,$percentage_of_time_normal,$avg_tests_of_ekstaziFalse,$percentage_ekstaziFalse,$avg_total_time_ekstaziFalse,$avg_analysis_time_ekstaziFalse,$avg_detection_time_ekstaziFalse,$percentage_of_time_ekstaziFalse,$avg_tests_of_ekstaziWithReachableStaticFields,$percentage_ekstaziWithReachableStaticFields,$avg_total_time_ekstaziWithReachableStaticFields,$avg_analysis_time_ekstaziWithReachableStaticFields,$avg_detection_time_ekstaziWithReachableStaticFields,$percentage_of_time_ekstaziWithReachableStaticFields"
  echo $full_string >> $currentDir/../../data/ekstazi_output_full.csv

  if [[ ${total_tests_of_ekstaziFalse} != "n/a" ]]; then
    sum_total_tests_of_normal=$(echo "${sum_total_tests_of_normal}+${total_tests_of_normal}" | bc -l)
    sum_total_tests_of_ekstaziFalse=$(echo "${sum_total_tests_of_ekstaziFalse}+${total_tests_of_ekstaziFalse}" | bc -l)
    sum_total_tests_of_ekstaziWithReachableStaticFields=$(echo "${sum_total_tests_of_ekstaziWithReachableStaticFields}+${total_tests_of_ekstaziWithReachableStaticFields}" | bc -l)
    num_of_lines=$((num_of_lines + 1))
  fi

done < tmp.csv # (cut -d',' -f1,2,4- ${input} | sort -u)

# weighted average number
average_percentage_of_time_ekstaziWithReachableStaticFields=$(echo "100*${sum_total_time_ekstaziWithReachableStaticFields}/${sum_total_time_run_iDFlakies}" | bc -l)
average_percentage_of_time_ekstaziFalse=$(echo "100*${sum_total_time_ekstaziFalse}/${sum_total_time_run_iDFlakies}" | bc -l)
sum_percentage_ekstaziWithReachableStaticFields=$(echo "100*${sum_total_tests_of_ekstaziWithReachableStaticFields}/${sum_total_tests_of_normal}" | bc -l)
sum_percentage_ekstaziFalse=$(echo "100*${sum_total_tests_of_ekstaziFalse}/${sum_total_tests_of_normal}" | bc -l)

# unweighted and weighted average numbers
average_time_run_iDFlakies=$(echo "${sum_total_time_run_iDFlakies}/(${whole_divisor})" | bc -l)
average_time_ekstaziFalse=$(echo "${sum_total_time_ekstaziFalse}/(${whole_divisor})" | bc -l)
average_time_ekstaziWithReachableStaticFields=$(echo "${sum_total_time_ekstaziWithReachableStaticFields}/(${whole_divisor})" | bc -l)

# unweighted percentage
ant_avg_percentage_ekstaziFalse=$(echo "${sum_percentage_of_test_ekstaziFalse}/(${whole_divisor})" | bc -l)
ant_avg_percentage_of_time_ekstaziFalse=$(echo "${sum_percentage_of_time_ekstaziFalse}/(${whole_divisor})" | bc -l)
ant_avg_percentage_ekstaziWithReachableStaticFields=$(echo "${sum_percentage_of_test_ekstaziWithReachableStaticFields}/(${whole_divisor})" | bc -l)
ant_avg_percentage_of_time_ekstaziWithReachableStaticFields=$(echo "${sum_percentage_of_time_ekstaziWithReachableStaticFields}/(${whole_divisor})" | bc -l)

ant_avg_select_tests_normal=$(echo "${sum_total_tests_of_normal}/(${whole_divisor})" | bc -l)
ant_avg_select_tests_ekstaziFalse=$(echo "${sum_total_tests_of_ekstaziFalse}/(${whole_divisor})" | bc -l)
ant_avg_select_tests_ekstaziWithReachableStaticFields=$(echo "${sum_total_tests_of_ekstaziWithReachableStaticFields}/(${whole_divisor})" | bc -l)

sum_full_string="Overall-1,$num_of_lines,$sum_total_time_run_iDFlakies,$sum_total_tests_of_normal,100.00,$average_time_run_iDFlakies,0,$average_time_run_iDFlakies,100.00,$sum_total_tests_of_ekstaziFalse,$sum_percentage_ekstaziFalse,$average_time_ekstaziFalse,,,$average_percentage_of_time_ekstaziFalse,$sum_total_tests_of_ekstaziWithReachableStaticFields,$sum_percentage_ekstaziWithReachableStaticFields,$average_time_ekstaziWithReachableStaticFields,,,$average_percentage_of_time_ekstaziWithReachableStaticFields"
echo $sum_full_string >> $currentDir/../../data/ekstazi_output_full.csv
ant_full_string="Overall-2,$num_of_lines,$average_time_run_iDFlakies,$ant_avg_select_tests_normal,100.00,$average_time_run_iDFlakies,0,$average_time_run_iDFlakies,100.00,$ant_avg_select_tests_ekstaziFalse,$ant_avg_percentage_ekstaziFalse,$average_time_ekstaziFalse,,,$ant_avg_percentage_of_time_ekstaziFalse,$ant_avg_select_tests_ekstaziWithReachableStaticFields,$ant_avg_percentage_ekstaziWithReachableStaticFields,$average_time_ekstaziWithReachableStaticFields,,,$ant_avg_percentage_of_time_ekstaziWithReachableStaticFields"
echo $ant_full_string >> $currentDir/../../data/ekstazi_output_full.csv
