#!/bin/bash
#
# mtr wrapper for various
# traceroute measurements
#
# Release 3.1.1
#

###
### PRE-RUN
###

### DEBUG
# set -x

### ENVIRONMENT

PATH=/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/bin:/sbin

### VARIABLES

_test_dscp1="0"
_test_source_name1=""
_test_source_address1=""
_test_source_as1=""
_custom_comment1=""
_custom_id1="0"
_geo_lon1="0.0"
_geo_lat1="0.0"
_result_delivery_array1=()

###
### FUNCTIONS
###

get_return_value1() { _return_value1="${?}"; }

run_test1()
{
  if [ "${_test_source_address1}" = "" ]; then _mtr1="mtr"; else _mtr1="mtr -a ${_test_source_address1}"; fi

  result1=$(timeout -k5s 120s ${_mtr1} -z -o "LBAWM" -c 10 -b -C -Q ${_test_dscp1} ${_test_target1} | grep -Ev "(,\\?\\?\\?|Mtr_Version)" 2>&1)
  get_return_value1
}

process_result1()
{
case ${_return_value1} in
0)
 _originalIFS1="$IFS"
 IFS=$'\n'

 for _tracerouteHopData1 in ${result1[@]}
 do
  output_oneliner1="{\"measurement_name\":\"traceroute_mtr1\""

  output_oneliner1="${output_oneliner1},\"test_source\":\"${_test_source_name1}\""
  output_oneliner1="${output_oneliner1},\"test_target\":\"${_test_target1}\""
  output_oneliner1="${output_oneliner1},\"test_dscp\":${_test_dscp1}"

  _mtr_timestamp1="${_tracerouteHopData1#*,}"
  _mtr_timestamp1="${_mtr_timestamp1%%,*}"
  output_oneliner1="${output_oneliner1},\"mtr_timestamp\":${_mtr_timestamp1}"

  _hop_number1="${_tracerouteHopData1#*,*,*,*,}"
  _hop_number1="${_hop_number1%%,*}"
  output_oneliner1="${output_oneliner1},\"hop_number\":${_hop_number1}"
  _hop_number2+=("${_hop_number1}")

  _hop_address1="${_tracerouteHopData1#*,*,*,*,*,}"
  _hop_address1="${_hop_address1%%,*}"
  output_oneliner1="${output_oneliner1},\"hop_address\":\"${_hop_address1}\""

  _hop_asn1="${_tracerouteHopData1#*,*,*,*,*,*,}"
  _hop_asn1="${_hop_asn1%%,*}"
  output_oneliner1="${output_oneliner1},\"hop_asn\":\"${_hop_asn1}\""
  _hop_asn2+=("${_hop_asn1}")

  _p_loss1="${_tracerouteHopData1#*,*,*,*,*,*,*,}"
  _p_loss1="${_p_loss1%%,*}"
  output_oneliner1="${output_oneliner1},\"packet_loss\":${_p_loss1}"

  _latency_min1="${_tracerouteHopData1#*,*,*,*,*,*,*,*,}"
  _latency_min1="${_latency_min1%%,*}"
  output_oneliner1="${output_oneliner1},\"latency_min\":${_latency_min1}"

  _latency_avg1="${_tracerouteHopData1#*,*,*,*,*,*,*,*,*,}"
  _latency_avg1="${_latency_avg1%%,*}"
  output_oneliner1="${output_oneliner1},\"latency_avg\":${_latency_avg1}"

  _latency_max1="${_tracerouteHopData1#*,*,*,*,*,*,*,*,*,*,}"
  _latency_max1="${_latency_max1%%,*}"
  output_oneliner1="${output_oneliner1},\"latency_max\":${_latency_max1}"

  _jitter_avg1="${_tracerouteHopData1#*,*,*,*,*,*,*,*,*,*,*,}"
  output_oneliner1="${output_oneliner1},\"jitter_avg\":${_jitter_avg1}"

  if [[ ${_hop_address1} =~ ${_test_target1} ]]; then _target_reached1="1"; else _target_reached1="0"; fi
  output_oneliner1="${output_oneliner1},\"test_target_reached\":${_target_reached1}"

  output_oneliner1="${output_oneliner1},\"custom_comment\":\"${_custom_comment1}\",\"custom_id\":\"${_custom_id1}\",\"geo_lon\":${_geo_lon1},\"geo_lat\":${_geo_lat1}"

  output_oneliner1="${output_oneliner1}}"
  output_oneliner2+=("${output_oneliner1}")

  ${_result_delivery1}
 done

 IFS="${_originalIFS1}"
 ;;
*)
 exit 1
 ;;
esac
}

send_result1()
{
(
for _result_target1 in ${_result_delivery_array1[@]}
do
  _result_target_credentials1="${_result_target1%%\@*}"
  _result_target_target1="${_result_target1##*\@}"
  curl --connect-timeout 5 -m 5 -s -k -X POST -H "Content-Type: application/json" -H "Authorization: Basic ${_result_target_credentials1}" -d "${output_oneliner1}" "${_result_target_target1}"
  sleep 0.$(( ($RANDOM % 3) + 1 ))
done
) &
}

print_result1() { echo "${output_oneliner1}"; }

indicate_last_reachable_hop1() { output_oneliner1="${output_oneliner1/traceroute_mtr1/ping_mtr1}"; }

set_test_source_name1() { if [ "${_test_source_name1}" = "" ]; then _test_source_name1="$(hostname -f)"; fi; }

find_as_handover_point1()
{
_as_source_hop_number1=()
_as_source_hop_index1=()
_as_handover_hop_number1=()
_as_handover_hop_index1=()
_handover_source_as_candidate_found1=0
_handover_as_candidate_found1=0

for _hop_index1 in ${!_hop_asn2[@]}
do
  if [ "${_hop_asn2[${_hop_index1}]}" = "AS???" ]; then continue; fi

  if [ "${_hop_asn2[${_hop_index1}]}" = "${_test_source_as1}" ]
  then _as_source_hop_number1+=(${_hop_number2[${_hop_index1}]}); _as_source_hop_index1+=(${_hop_index1})
  else _as_handover_hop_number1+=(${_hop_number2[${_hop_index1}]}); _as_handover_hop_index1+=(${_hop_index1});
  fi
done

if [ ${#_as_source_hop_number1[@]} -ge 2 ] && [ $(( ${_as_source_hop_number1[-1]} - 1 )) -eq ${_as_source_hop_number1[-2]} ]
then
  _handover_source_as_candidate_found1=1
fi

_handover_hop_index1=$(( ${_as_handover_hop_number1[0]} - 1 ))
_handover_hop_index2=$(( ${_as_handover_hop_number1[1]} - 1 ))
if [ ${_handover_hop_index1} -ge 0 ] && [ ${_handover_hop_index2} -ge 0 ]
then
  if [ ${#_as_handover_hop_number1[@]} -ge 2 ] && [ "${_hop_asn2[${_handover_hop_index1}]}" = "${_hop_asn2[${_handover_hop_index2}]}" ] && [ $(( ${_as_handover_hop_number1[1]} -1 )) -eq ${_as_handover_hop_number1[0]} ]
  then
    _handover_as_candidate_found1=1
  fi

  if [ $(( ${_as_source_hop_number1[-1]} + 1 )) -eq ${_as_handover_hop_number1[0]} ]
  then
    if [ ${_handover_source_as_candidate_found1} -eq 1 ]; then _handover1=${_as_source_hop_index1[-1]}; fi
    if [ ${_handover_as_candidate_found1} -eq 1 ]; then _handover2=${_as_handover_hop_index1[1]}; fi
  fi

  if [ ${_handover_source_as_candidate_found1} -eq 1 ] && [ "${_handover1}" != "" ]
  then
    output_oneliner1="${output_oneliner2[${_handover1}]/traceroute_mtr1/handover_mtr1}"
    [[ ${output_oneliner1} =~ (.*),\"hop_asn\":\"AS[0-9\?]+\",(.*) ]]
    output_oneliner1="${BASH_REMATCH[1]},\"hop_asn\":\"${_hop_asn2[$(( ${_handover1} + 1 ))]}\",${BASH_REMATCH[2]}"
    ${_result_delivery1}
  fi

  if [ ${_handover_as_candidate_found1} -eq 1 ] && [ "${_handover2}" != "" ]
  then
    output_oneliner1="${output_oneliner2[${_handover2}]/traceroute_mtr1/handover_mtr2}"
    [[ ${output_oneliner1} =~ (.*),\"hop_asn\":\"AS[0-9\?]+\",(.*) ]]
    output_oneliner1="${BASH_REMATCH[1]},\"hop_asn\":\"${_hop_asn2[${_handover2}]}\",${BASH_REMATCH[2]}"
    ${_result_delivery1}
  fi
fi
}

###
### LOOPS
###

while getopts "t:q:d:s:A:H:c:i:o:l:" _options1; do
 case ${_options1} in
 t)
  _test_target1="${OPTARG}"
  ;;
 q)
  if ! [[ ${OPTARG} =~ ^[0-9]+$ ]]; then echo "Error: Integer value expected."; exit 1; fi
  _test_dscp1="${OPTARG}"
  ;;
 d)
  read -r -a _result_delivery_array1 <<< "${OPTARG}"
  ;;
 s)
  _test_source_name1="${OPTARG}"
  ;;
 A)
  _test_source_address1="${OPTARG}"
  ;;
 H)
  _test_source_as1="${OPTARG}"
  ;;
 c)
  _custom_comment1="${OPTARG}"
  ;;
 i)
  _custom_id1="${OPTARG}"
  ;;
 o)
  _geo_lon1="${OPTARG}"
  ;;
 l)
  _geo_lat1="${OPTARG}"
  ;;
 *)
  exit 1
  ;;
 esac
done

if [ "${_result_delivery_array1[0]}" = "" ]; then _result_delivery1="print_result1"; else _result_delivery1="send_result1"; fi

set_test_source_name1

run_test1
process_result1

indicate_last_reachable_hop1
${_result_delivery1}

if [[ ${_test_source_as1} =~ ^AS[0-9]+ ]]; then find_as_handover_point1; fi

###
### POST-RUN
###

wait

exit "${_return_value1}"

# EOF
