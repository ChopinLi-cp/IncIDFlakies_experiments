#!/usr/bin/env bash

# The output is like 
# proj, module, test, # total tests of FIC, # total tests of starts (selectMore=true), 
# y/n, # total tests of starts (selectMore=false), y/n, percentage  
# NOTE: This script is used to extract the information according to the input


if [[ $1 == "" ]]; then
    echo "arg1 - full path to the input file (eg. commits.csv)"
    echo "this script is to collect the output file for starts part in the RQ1"
    exit
fi

currentDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

input=$1
inputProj=$currentDir"/../../projects"

cut -d',' -f1,2,4- ${input} | sort -u > tmp.csv

echo -n "" > $currentDir/../../data/starts_output_RQ1.csv

sum_total_tests_of_normal=0
sum_total_time_run_iDFlakies=0.00
average_time_run_iDFlakies=0.00
ant_total_select_tests_normal=0
ant_avg_select_tests_normal=0
sum_total_tests_of_startsWithReachableStaticFields=0
sum_percentage_startsWithReachableStaticFields=0.00
sum_total_time_startsWithReachableStaticFields=0.00
average_percentage_of_time_startsWithReachableStaticFields=0.00
ant_total_select_tests_startsWithReachableStaticFields=0
ant_avg_select_tests_startsWithReachableStaticFields=0
sum_total_tests_of_startsFalse=0
sum_percentage_startsFalse=0.00
sum_total_time_startsFalse=0.00
average_percentage_of_time_startsFalse=0.00
ant_total_select_tests_startsFalse=0
ant_avg_select_tests_startsFalse=0
num_of_lines=0
whole_divisor=0
total_sum_percentage_of_test_startsFalse=0.00
total_sum_percentage_of_time_startsFalse=0.00
total_sum_percentage_of_test_startsWithReachableStaticFields=0.00
total_sum_percentage_of_time_startsWithReachableStaticFields=0.00

echo "# proj, module, fic_sha, # tests selected (normal), % tests selected from normal, overall time, analysis time, detection time, % overall time from normal, # tests selected (starts), % tests selected from normal, overall time, analysis time, detection time, % overall time from normal, # tests selected (IncIDFlakies_E), % tests selected from normal, overall time, analysis time, detection time, % overall time from normal"  >> $currentDir/../../data/starts_output_RQ1.csv
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

  total_tests_of_startsFalse=0
  avg_tests_of_startsFalse=0
  percentage_startsFalse=0.00
  total_time_startsFalse=0.00
  avg_total_time_startsFalse=0.00
  total_analysis_time_startsFalse=0.00
  analysis_time_startsFalse=0.00
  avg_analysis_time_startsFalse=0.00
  detection_time_startsFalse=0.00
  avg_detection_time_startsFalse=0.00
  total_detection_time_startsFalse=0.00
  percentage_of_time_startsFalse=0.00

  total_tests_of_startsWithReachableStaticFields=0
  avg_total_tests_of_startsWithReachableStaticFields=0
  percentage_startsWithReachableStaticFields=0.00
  total_time_startsWithReachableStaticFields=0.00
  avg_total_time_startsWithReachableStaticFields=0.00
  total_analysis_time_startsWithReachableStaticFields=0.00
  analysis_time_startsWithReachableStaticFields=0.00
  avg_analysis_time_startsWithReachableStaticFields=0.00
  total_detection_time_startsWithReachableStaticFields=0.00
  detection_time_startsWithReachableStaticFields=0.00
  avg_detection_time_startsWithReachableStaticFields=0.00
  percentage_of_time_startsWithReachableStaticFields=0.00
  
  sum_percentage_of_test_startsFalse=0.00
  sum_percentage_of_time_startsFalse=0.00
  sum_percentage_of_test_startsWithReachableStaticFields=0.00
  sum_percentage_of_time_startsWithReachableStaticFields=0.00

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

      if [[ -d ${inputProj}/${slug}/${module}/.dtfixingtools_starts_${nextsha} ]]; then
        selected_tests_FILE=${inputProj}/${slug}/${module}/.dtfixingtools_starts_${nextsha}/selected-tests
        if [[ -f ${selected_tests_FILE} ]]; then
          total_tests_of_startsFalse_b=$(cat $selected_tests_FILE | grep -c "")
          total_tests_of_startsFalse=$(echo "${total_tests_of_startsFalse} + ${total_tests_of_startsFalse_b}" | bc -l)
          startsFalse_selected_tests_percent_b=$(echo "100*${total_tests_of_startsFalse_b}/${total_tests_of_normal_b}" | bc -l)
          sum_percentage_of_test_startsFalse=$(echo "${sum_percentage_of_test_startsFalse} + ${startsFalse_selected_tests_percent_b}" | bc -l)
        fi
        timeFILE=${inputProj}/${slug}/${module}/.dtfixingtools_starts_${nextsha}/time
        if [[ -f $timeFILE ]]; then
          analysis_time_startsFalse=$(cut -d',' -f1  ${timeFILE})
          total_analysis_time_startsFalse=$(echo "${total_analysis_time_startsFalse} + ${analysis_time_startsFalse}" | bc -l)
          detection_time_startsFalse=$(cut -d',' -f2  ${timeFILE})
          total_detection_time_startsFalse=$(echo "${total_detection_time_startsFalse} + ${detection_time_startsFalse}" | bc -l)
        fi
        total_time_startsFalse_b=$(echo "${analysis_time_startsFalse} + ${detection_time_startsFalse}" | bc -l)
        total_time_startsFalse=$(echo "${total_time_startsFalse} + ${total_time_startsFalse_b}" | bc -l)
        percentage_of_time_startsFalse_b=$(echo "100*${total_time_startsFalse_b}/${time_run_iDFlakies_b}" | bc -l)
        sum_percentage_of_time_startsFalse=$(echo "${sum_percentage_of_time_startsFalse} + ${percentage_of_time_startsFalse_b}" | bc -l)
      fi

      if [[ -d ${inputProj}/${slug}/${module}/.dtfixingtools_starts_plus_${nextsha} ]]; then
        selected_tests_FILE=${inputProj}/${slug}/${module}/.dtfixingtools_starts_plus_${nextsha}/selected-tests
        if [[ -f $selected_tests_FILE ]]; then
          total_tests_of_startsWithReachableStaticFields_b=$(cat $selected_tests_FILE | grep -c "")
          total_tests_of_startsWithReachableStaticFields=$(echo "${total_tests_of_startsWithReachableStaticFields} + ${total_tests_of_startsWithReachableStaticFields_b}" | bc -l)
          percentage_startsWithReachableStaticFields_b=$(echo "100*${total_tests_of_startsWithReachableStaticFields_b}/${total_tests_of_normal_b}" | bc -l)
          sum_percentage_of_test_startsWithReachableStaticFields=$(echo "${sum_percentage_of_test_startsWithReachableStaticFields} + ${percentage_startsWithReachableStaticFields_b}" | bc -l)
        fi
        timeFILE=${inputProj}/${slug}/${module}/.dtfixingtools_starts_plus_${nextsha}/time
        if [[ -f $timeFILE ]]; then
          analysis_time_startsWithReachableStaticFields=$(cut -d',' -f1  ${timeFILE})
          total_analysis_time_startsWithReachableStaticFields=$(echo "${total_analysis_time_startsWithReachableStaticFields} + ${analysis_time_startsWithReachableStaticFields}" | bc -l)
          detection_time_startsWithReachableStaticFields=$(cut -d',' -f2  ${timeFILE})
          total_detection_time_startsWithReachableStaticFields=$(echo "${total_detection_time_startsWithReachableStaticFields} + ${detection_time_startsWithReachableStaticFields}" | bc -l)
        fi
        total_time_startsWithReachableStaticFields_b=$(echo "${analysis_time_startsWithReachableStaticFields} + ${detection_time_startsWithReachableStaticFields}" | bc -l)
        total_time_startsWithReachableStaticFields=$(echo "${total_time_startsWithReachableStaticFields} + ${total_time_startsWithReachableStaticFields_b}" | bc -l)
        percentage_of_time_startsWithReachableStaticFields_b=$(echo "100*${total_time_startsWithReachableStaticFields_b}/${time_run_iDFlakies_b}" | bc -l)
        sum_percentage_of_time_startsWithReachableStaticFields=$(echo "${sum_percentage_of_time_startsWithReachableStaticFields} + ${percentage_of_time_startsWithReachableStaticFields_b}" | bc -l)
      fi
      divisor=$(echo "${divisor} + 1" | bc -l)
      whole_divisor=$(echo "${whole_divisor} + 1" | bc -l)
    fi
  done

  avg_tests_of_normal=$(echo "${total_tests_of_normal} / ${divisor}" | bc -l)
  avg_time_run_iDFlakies=$(echo "${time_run_iDFlakies} / ${divisor}" | bc -l)
  avg_tests_of_startsFalse=$(echo "${total_tests_of_startsFalse} / ${divisor}" | bc -l)
  avg_total_time_startsFalse=$(echo "${total_time_startsFalse} / ${divisor}" | bc -l)
  avg_analysis_time_startsFalse=$(echo "${total_analysis_time_startsFalse} / ${divisor}" | bc -l)
  avg_detection_time_startsFalse=$(echo "${total_detection_time_startsFalse} / ${divisor}" | bc -l)
  avg_tests_of_startsWithReachableStaticFields=$(echo "${total_tests_of_startsWithReachableStaticFields} / ${divisor}" | bc -l)
  avg_total_time_startsWithReachableStaticFields=$(echo "${total_time_startsWithReachableStaticFields} / ${divisor}" | bc -l)
  avg_analysis_time_startsWithReachableStaticFields=$(echo "${total_analysis_time_startsWithReachableStaticFields} / ${divisor}" | bc -l)
  avg_detection_time_startsWithReachableStaticFields=$(echo "${total_detection_time_startsWithReachableStaticFields} / ${divisor}" | bc -l)

  sum_total_time_run_iDFlakies=$(echo "${sum_total_time_run_iDFlakies} + ${time_run_iDFlakies}" | bc -l)
  sum_total_time_startsFalse=$(echo "${sum_total_time_startsFalse} + ${total_time_startsFalse}" | bc -l)
  sum_total_time_startsWithReachableStaticFields=$(echo "${sum_total_time_startsWithReachableStaticFields} + ${total_time_startsWithReachableStaticFields}" | bc -l)
  
  avg_detection_time_run_iDFlakies=${avg_time_run_iDFlakies}

  percentage_startsFalse=$(echo "${sum_percentage_of_test_startsFalse}/${divisor}" | bc -l)
  percentage_of_time_startsFalse=$(echo "${sum_percentage_of_time_startsFalse}/${divisor}" | bc -l) 
  percentage_startsWithReachableStaticFields=$(echo "${sum_percentage_of_test_startsWithReachableStaticFields}/${divisor}" | bc -l)
  percentage_of_time_startsWithReachableStaticFields=$(echo "${total_sum_percentage_of_time_startsWithReachableStaticFields}/${divisor}" | bc -l)
  full_string="$slug,$module,$fic_short_sha,$avg_tests_of_normal,$percentage_normal,$avg_time_run_iDFlakies,$avg_analysis_time_run_iDFlakies,$avg_detection_time_run_iDFlakies,$percentage_of_time_normal,$avg_tests_of_startsFalse,$percentage_startsFalse,$avg_total_time_startsFalse,$avg_analysis_time_startsFalse,$avg_detection_time_startsFalse,$percentage_of_time_startsFalse,$avg_tests_of_startsWithReachableStaticFields,$percentage_startsWithReachableStaticFields,$avg_total_time_startsWithReachableStaticFields,$avg_analysis_time_startsWithReachableStaticFields,$avg_detection_time_startsWithReachableStaticFields,$percentage_of_time_startsWithReachableStaticFields"
  echo $full_string >> $currentDir/../../data/starts_output_RQ1.csv

  if [[ ${total_tests_of_startsFalse} != "n/a" ]]; then
    sum_total_tests_of_normal=$(echo "${sum_total_tests_of_normal}+${total_tests_of_normal}" | bc -l)
    sum_total_tests_of_startsFalse=$(echo "${sum_total_tests_of_startsFalse}+${total_tests_of_startsFalse}" | bc -l)
    sum_total_tests_of_startsWithReachableStaticFields=$(echo "${sum_total_tests_of_startsWithReachableStaticFields}+${total_tests_of_startsWithReachableStaticFields}" | bc -l)
    num_of_lines=$((num_of_lines + 1))
    total_sum_percentage_of_test_startsFalse=$(echo "${total_sum_percentage_of_test_startsFalse}+${sum_percentage_of_test_startsFalse}" | bc -l)
    total_sum_percentage_of_time_startsFalse=$(echo "${total_sum_percentage_of_time_startsFalse}+${sum_percentage_of_time_startsFalse}" | bc -l)
    total_sum_percentage_of_test_startsWithReachableStaticFields=$(echo "${total_sum_percentage_of_test_startsWithReachableStaticFields}+${sum_percentage_of_test_startsWithReachableStaticFields}" | bc -l)
    total_sum_percentage_of_time_startsWithReachableStaticFields=$(echo "${total_sum_percentage_of_time_startsWithReachableStaticFields}+${sum_percentage_of_time_startsWithReachableStaticFields}" | bc -l)
  fi

done < tmp.csv # (cut -d',' -f1,2,4- ${input} | sort -u)

# weighted average number
average_percentage_of_time_startsWithReachableStaticFields=$(echo "100*${sum_total_time_startsWithReachableStaticFields}/${sum_total_time_run_iDFlakies}" | bc -l)
average_percentage_of_time_startsFalse=$(echo "100*${sum_total_time_startsFalse}/${sum_total_time_run_iDFlakies}" | bc -l)
sum_percentage_startsWithReachableStaticFields=$(echo "100*${sum_total_tests_of_startsWithReachableStaticFields}/${sum_total_tests_of_normal}" | bc -l)
sum_percentage_startsFalse=$(echo "100*${sum_total_tests_of_startsFalse}/${sum_total_tests_of_normal}" | bc -l)

# unweighted and weighted average numbers
average_time_run_iDFlakies=$(echo "${sum_total_time_run_iDFlakies}/(${whole_divisor})" | bc -l)
average_time_startsFalse=$(echo "${sum_total_time_startsFalse}/(${whole_divisor})" | bc -l)
average_time_startsWithReachableStaticFields=$(echo "${sum_total_time_startsWithReachableStaticFields}/(${whole_divisor})" | bc -l)

# unweighted percentage
ant_avg_percentage_startsFalse=$(echo "${total_sum_percentage_of_test_startsFalse}/(${whole_divisor})" | bc -l)
ant_avg_percentage_of_time_startsFalse=$(echo "${total_sum_percentage_of_time_startsFalse}/(${whole_divisor})" | bc -l)
ant_avg_percentage_startsWithReachableStaticFields=$(echo "${total_sum_percentage_of_test_startsWithReachableStaticFields}/(${whole_divisor})" | bc -l)
ant_avg_percentage_of_time_startsWithReachableStaticFields=$(echo "${total_sum_percentage_of_time_startsWithReachableStaticFields}/(${whole_divisor})" | bc -l)

ant_avg_select_tests_normal=$(echo "${sum_total_tests_of_normal}/(${whole_divisor})" | bc -l)
ant_avg_select_tests_startsFalse=$(echo "${sum_total_tests_of_startsFalse}/(${whole_divisor})" | bc -l)
ant_avg_select_tests_startsWithReachableStaticFields=$(echo "${sum_total_tests_of_startsWithReachableStaticFields}/(${whole_divisor})" | bc -l)

sum_full_string="Overall-1,$num_of_lines,$sum_total_time_run_iDFlakies,$sum_total_tests_of_normal,100.00,$average_time_run_iDFlakies,0,$average_time_run_iDFlakies,100.00,$sum_total_tests_of_startsFalse,$sum_percentage_startsFalse,$average_time_startsFalse,,,$average_percentage_of_time_startsFalse,$sum_total_tests_of_startsWithReachableStaticFields,$sum_percentage_startsWithReachableStaticFields,$average_time_startsWithReachableStaticFields,,,$average_percentage_of_time_startsWithReachableStaticFields"
echo $sum_full_string >> $currentDir/../../data/starts_output_RQ1.csv
ant_full_string="Overall-2,$num_of_lines,$average_time_run_iDFlakies,$ant_avg_select_tests_normal,100.00,$average_time_run_iDFlakies,0,$average_time_run_iDFlakies,100.00,$ant_avg_select_tests_startsFalse,$ant_avg_percentage_startsFalse,$average_time_startsFalse,,,$ant_avg_percentage_of_time_startsFalse,$ant_avg_select_tests_startsWithReachableStaticFields,$ant_avg_percentage_startsWithReachableStaticFields,$average_time_startsWithReachableStaticFields,,,$ant_avg_percentage_of_time_startsWithReachableStaticFields"
echo $ant_full_string >> $currentDir/../../data/starts_output_RQ1.csv
