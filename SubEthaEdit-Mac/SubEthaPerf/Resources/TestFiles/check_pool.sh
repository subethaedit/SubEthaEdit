#!/bin/bash

#< Nagios plugin wrapper around poolstats.sh to check http-based pools
# for host availability as well as HTTP sanity 

# Executables
BASENAME="/usr/bin/basename"
CUT="/usr/bin/cut"
ECHO="/bin/echo"
EGREP="/bin/egrep"
GREP="/bin/grep"
POOLSTATS="/home/bigip/bin/poolstats.sh"
SED="/usr/bin/sed"

# Variable initialistion
CRITICAL_FLAG=0
WARNING_FLAG=0
VERBOSE_FLAG=0
URI=""
HOST_ADDRESS=""

THIS_PROG=$( ${BASENAME} $0 )


# Exit Status Codes
OK=0
WARNING=1
CRITICAL=2
UNKNOWN=3

function usage {
   {
      ${ECHO} "Usage: ${THIS_PROG} -w <warn> -c <crit> -U <uri> -H <host> -p <pool> [-v]" 
      ${ECHO} "       -w       Specify warning threshold"
      ${ECHO} "       -c       Specify critical threshold"
      ${ECHO} "       -U       Specify URI to check"
      ${ECHO} "       -H       Specify Host header to add"
      ${ECHO} "       -p       Specify pool to check"
   } >&2
}

function print_error {
   ${ECHO} "Error: $@" >&2
}

function check_remaining_args {
   if [ "$1" -ne "0" ]; then
      (( VERBOSE_FLAG )) && {
         print_error "Remaining argument count not zero"
      }
      usage
      ${ECHO} "UNKNOWN: Extra arguments passed to plugin"
      exit ${UNKNOWN}
   fi
}

function parse_args {
   ERROR_COUNT=0
   if [ "${CRITICAL_FLAG}" -ne "1" ]; then
      (( VERBOSE_FLAG )) && {
         print_error "-c option not present"
      }
      (( ERROR_COUNT = ERROR_COUNT + 1 ))
   else
      # Let's check that the critical threshold contains a sane value
      ${ECHO} "${CRITICAL_THRESHOLD}" | ${EGREP} '^[0-9]+%?$' >/dev/null 2>&1
      if [ "$?" -ne "0" ]; then
         (( VERBOSE_FLAG )) && {
            print_error "Invalid critical threshold value passed"
         }
         (( ERROR_COUNT = ERROR_COUNT + 1 ))
      fi
      # This should never be true, a usage error would be thrown by the getopts while loop
      if [ -z "${CRITICAL_THRESHOLD}" ]; then
      (( VERBOSE_FLAG )) && {
         print_error "Critical threshold not set"
      }
      (( ERROR_COUNT = ERROR_COUNT + 1 ))
      fi
   fi

   if [ "${WARNING_FLAG}" -ne "1" ]; then
      (( VERBOSE_FLAG )) && {
         print_error "-w option not present"
      }
      (( ERROR_COUNT = ERROR_COUNT + 1 ))
   else
      # Let's check that the warning threshold contains a sane value
      ${ECHO} "${WARNING_THRESHOLD}" | ${EGREP} '^[0-9]+%?$' >/dev/null 2>&1
      if [ "$?" -ne "0" ]; then
         (( VERBOSE_FLAG )) && {
            print_error "Invalid warning threshold value passed"
         }
         (( ERROR_COUNT = ERROR_COUNT + 1 ))
      fi
      # This should never be true, a usage error would be thrown by the getopts while loop
      if [ -z "${WARNING_THRESHOLD}" ]; then
      (( VERBOSE_FLAG )) && {
         print_error "Warning threshold not set"
      }
      (( ERROR_COUNT = ERROR_COUNT + 1 ))
      fi
   fi

   if [ "${URI}" = "" ]; then
      (( VERBOSE_FLAG )) && {
         print_error "-u option not present"
      }
      (( ERROR_COUNT = ERROR_COUNT + 1 ))
   else
      ${ECHO} "${URI}" | ${GREP} "^/.*$" >/dev/null 2>&1
      if [ "$?" -ne "0" ]; then
         (( VERBOSE_FLAG )) && {
	    print_error "URI must start with leading /"
	 }
	 (( ERROR_COUNT = ERROR_COUNT + 1 ))
      fi
   fi

   if [ "${HOST_ADDRESS}" = "" ]; then
      (( VERBOSE_FLAG )) && {
         print_error "-H option not present"
      }
      (( ERROR_COUNT = ERROR_COUNT + 1 ))
   fi

   if [ "${POOL}" = "" ]; then
      (( VERBOSE_FLAG )) && {
         print_error "-p option not present"
      }
      (( ERROR_COUNT = ERROR_COUNT + 1 ))
   fi

   if [ "${ERROR_COUNT}" -gt "0" ]; then
      (( VERBOSE_FLAG )) && {
         print_error "${ERROR_COUNT} error(s) found whilst parsing arguments"
      }
      ${ECHO} "UNKNOWN: Errors encountered passing plugin arguments"
      exit ${UNKNOWN}
   fi

}

function perform_check {
   OUTPUT=$( ${POOLSTATS} -n -p ${POOL} -u http://${HOST_ADDRESS}${URI} )
   POOL_STATUS=$( ${ECHO} "${OUTPUT}" | ${SED} -n '1p' )
   HTTP_STATUS=$( ${ECHO} "${OUTPUT}" | ${SED} -n '$p' )
   (( VERBOSE_FLAG )) && {
      ${ECHO} "POOL_STATUS: ${POOL_STATUS}"
      ${ECHO} "HTTP_STATUS: ${HTTP_STATUS}"
   }
   P_DOWN=$( ${ECHO} "${POOL_STATUS}" | ${CUT} -d":" -f1 )
   P_TOTAL=$( ${ECHO} "${POOL_STATUS}" | ${CUT} -d":" -f2 )
   P_PERCENT=$( ${ECHO} "${POOL_STATUS}" | ${CUT} -d":" -f3 )
   H_DOWN=$( ${ECHO} "${HTTP_STATUS}" | ${CUT} -d":" -f1 )
   H_TOTAL=$( ${ECHO} "${HTTP_STATUS}" | ${CUT} -d":" -f2 )
   H_PERCENT=$( ${ECHO} "${HTTP_STATUS}" | ${CUT} -d":" -f3 )
   ${ECHO} "${WARNING_THRESHOLD}" | ${GREP} ".*%$" >/dev/null 2>&1
   if [ "$?" -eq "0" ]; then
      WARNING_TYPE="PERCENT"
      WARNING_THRESHOLD=$( ${ECHO} "${WARNING_THRESHOLD}" | ${SED} 's/^\(.*\)%$/\1/' )
   else
      WARNING_TYPE="VALUE"
   fi
   ${ECHO} "${CRITICAL_THRESHOLD}" | ${GREP} ".*%$" >/dev/null 2>&1
   if [ "$?" -eq "0" ]; then
      CRITICAL_TYPE="PERCENT"
      CRITICAL_THRESHOLD=$( ${ECHO} "${CRITICAL_THRESHOLD}" | ${SED} 's/^\(.*\)%$/\1/' )
   else
      CRITICAL_TYPE="VALUE"
   fi
   if [ "${WARNING_THRESHOLD}" -gt "${CRITICAL_THRESHOLD}" ]; then
      (( VERBOSE_FLAG )) && {
         print_error "Warning threshold greater than critical threshold"
      }
      ${ECHO} "UNKNOWN: -w > -c"
      exit "${UNKNOWN}"
   fi
   case "${CRITICAL_TYPE}" in
      "PERCENT" ) if [ "${P_PERCENT}" -ge "${CRITICAL_THRESHOLD}" ]; then
                     (( VERBOSE_FLAG )) && {
		        ${ECHO} "--[ ${P_PERCENT}% >= ${CRITICAL_THRESHOLD}% DOWN IN POOL ]"
		     }
		     ${ECHO} "CRITICAL: ${P_PERCENT}% of pool members down"
		     exit "${CRITICAL}"
                  fi
		  if [ "${H_PERCENT}" -ge "${CRITICAL_THRESHOLD}" ]; then
		     (( VERBOSE_FLAG )) && {
		        ${ECHO} "--[ ${H_PERCENT}% >= ${CRITICAL_THRESHOLD}% RETURNING ERRORS ]"
		     }
		     ${ECHO} "CRITICAL: ${H_PERCENT}% of members returning HTTP errors"
		     exit "${CRITICAL}"
                  fi
                  ;;
      "VALUE"   ) if [ "${P_DOWN}" -ge "${CRITICAL_THRESHOLD}" ]; then
                     (( VERBOSE_FLAG )) && {
		        ${ECHO} "--[ ${P_DOWN}% >= ${CRITICAL_THRESHOLD}% DOWN IN POOL ]"
		     }
		     ${ECHO} "CRITICAL: ${P_DOWN} pool members down"
		     exit "${CRITICAL}"
                  fi
		  if [ "${H_DOWN}" -ge "${CRITICAL_THRESHOLD}" ]; then
		     (( VERBOSE_FLAG )) && {
		        ${ECHO} "--[ ${H_DOWN} >= ${CRITICAL_THRESHOLD}% RETURNING ERRORS ]"
		     }
		     ${ECHO} "CRITICAL: ${H_DOWN} members returning HTTP errors"
		     exit "${CRITICAL}"
                  fi
                  ;;
        *       ) : # Never reached
	          ;;
   esac
   case "${WARNING_TYPE}" in
      "PERCENT" ) if [ "${P_PERCENT}" -ge "${WARNING_THRESHOLD}" ]; then
                     (( VERBOSE_FLAG )) && {
		        ${ECHO} "--[ ${P_PERCENT}% >= ${WARNING_THRESHOLD}% DOWN IN POOL ]"
		     }
		     ${ECHO} "WARNING: ${P_PERCENT}% of pool members down"
		     exit "${WARNING}"
                  fi
		  if [ "${H_PERCENT}" -ge "${WARNING_THRESHOLD}" ]; then
		     (( VERBOSE_FLAG )) && {
		        ${ECHO} "--[ ${H_PERCENT}% >= ${WARNING_THRESHOLD}% RETURNING ERRORS ]"
		     }
		     ${ECHO} "WARNING: ${H_PERCENT}% of members returning HTTP errors"
		     exit "${WARNING}"
                  fi
                  ;;
      "VALUE"   ) if [ "${P_DOWN}" -ge "${WARNING_THRESHOLD}" ]; then
                     (( VERBOSE_FLAG )) && {
		        ${ECHO} "--[ ${P_DOWN}% >= ${WARNING_THRESHOLD}% DOWN IN POOL ]"
		     }
		     ${ECHO} "WARNING: ${P_DOWN} pool members down"
		     exit "${WARNING}"
                  fi
		  if [ "${H_DOWN}" -ge "${WARNING_THRESHOLD}" ]; then
		     (( VERBOSE_FLAG )) && {
		        ${ECHO} "--[ ${H_DOWN} >= ${WARNING_THRESHOLD}% RETURNING ERRORS ]"
		     }
		     ${ECHO} "WARNING: ${H_DOWN} members returning HTTP errors"
		     exit "${WARNING}"
                  fi
                  ;;
        *       ) : # Never reached
	          ;;
   esac
}

# Nagios recommends multiple level verbosity (e.g. -vvv)
# but we will not bother with that
while getopts ":c:p:H:w:U:v" OPTION; do
  case ${OPTION} in
    "c")   if [ "${CRITICAL_FLAG}" -ne "0" ]; then
              (( VERBOSE_FLAG )) && {
                 print_error "More than one -c option specified"
              }
              ${ECHO} "UNKNOWN: More than one -c option passed to plugin"
              exit "${UNKNOWN}"
           fi
           CRITICAL_FLAG="1"
           CRITICAL_THRESHOLD="${OPTARG}"
           ;;
    "H")   if [ "${HOST_ADDRESS}" != "" ]; then
              (( VERBOSE_FLAG )) && {
	         print_error "More than one -H option specified"
              }
	      ${ECHO} "UNKNOWN: More than one -H option passed to plugin"
	      exit "${UNKNOWN}"
           fi
	   HOST_ADDRESS="${OPTARG}"
	   ;;
    "p")   if [ "${POOL}" != "" ]; then
              (( VERBOSE_FLAG )) && {
	         print_error "More than one -p option specified"
              }
	      ${ECHO} "UNKNOWN: More than one -p option passed to plugin"
	      exit "${UNKNOWN}"
           fi
	   POOL="${OPTARG}"
	   ;;
    "U")   if [ "${URI}" != "" ]; then
              (( VERBOSE_FLAG )) && {
	         print_error "More than one -u option specified"
	      }
	      ${ECHO} "UNKNOWN: More than one -u option passed to plugin"
	      exit "${UNKNOWN}"
           fi
	   URI="${OPTARG}"
	   ;;
    "w")   if [ "${WARNING_FLAG}" -ne "0" ]; then
              (( VERBOSE_FLAG )) && {
                 print_error "More than one -w option specified"
              }
              ${ECHO} "UNKNOWN: More than one -w option passed to plugin"
              exit "${UNKNOWN}"
           fi
           WARNING_FLAG="1"
           WARNING_THRESHOLD="${OPTARG}"
           ;;
    "v")   VERBOSE_FLAG="1"
           ;;
     * )   usage
           exit ${UNKNOWN}
           ;;
  esac
done

# Even though we're not expecting extra args, let's be thorough
shift $(( ${OPTIND} - 1 ))

check_remaining_args "$#"
parse_args
perform_check

${ECHO} "OK: Pool status within tolerable limits"
exit ${OK}
