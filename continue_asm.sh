#!/bin/bash -fe
#
# Inspired by v1 run_e3sm script as well as SCREAM group simplified run script.


main() {

# For debugging, uncomment line below
#set -x

# --- Configuration flags ----

# Machine and project
readonly MACHINE=pm-cpu
readonly PROJECT="e3sm"

# Simulation
readonly COMPSET="F1850"
readonly RESOLUTION="ne30pg2_EC30to60E2r2"
# BEFORE RUNNING : CHANGE the following CASE_NAME to desired value
readonly CASE_NAME="f_pre_ind_asm_test"
# If this is part of a simulation campaign, ask your group lead about using a case_group label
# readonly CASE_GROUP=""

# Code and compilation
#readonly CHECKOUT="20210806"
#readonly BRANCH="master"
#readonly CHERRY=( )
readonly DEBUG_COMPILE=FALSE

# Run options
readonly MODEL_START_TYPE="branch"  # 'initial', 'continue', 'branch', 'hybrid'
readonly START_DATE="1854-02-01"

# Additional options for 'branch' and 'hybrid'
readonly GET_REFCASE=FALSE
readonly RUN_REFDIR="/pscratch/sd/j/jtolento/E3SM/f_pre_ind_asm/run"
readonly RUN_REFCASE="f_pre_ind_asm"
readonly RUN_REFDATE="1854-02-01"   # same as MODEL_START_DATE for 'branch', can be different for 'hybrid'

# Set paths
#readonly CODE_ROOT="${HOME}/E3SMv2/code/${CHECKOUT}"
#readonly CASE_ROOT="/global/cscratch1/sd/${USER}/E3SMv2/${CASE_NAME}"
readonly CODE_ROOT="${HOME}/E3SM_JPT"
readonly CASE_ROOT="${SCRATCH}/E3SM/${CASE_NAME}"

# Sub-directories
readonly CASE_BUILD_DIR=${CASE_ROOT}/build
readonly CASE_ARCHIVE_DIR=${CASE_ROOT}/archive

# Define type of run
#  short tests: 'XS_2x5_ndays', 'XS_1x10_ndays', 'S_1x10_ndays',
#               'M_1x10_ndays', 'M2_1x10_ndays', 'M80_1x10_ndays', 'L_1x10_ndays'
#  or 'production' for full simulation
readonly run='production'
if [ "${run}" != "production" ]; then

  # Short test simulations
  tmp=($(echo $run | tr "_" " "))
  layout=${tmp[0]}
  units=ndays
  resubmit=$(( ${tmp[1]%%x*} -1 ))
  length=3

  readonly CASE_SCRIPTS_DIR=${CASE_ROOT}/tests/${run}/case_scripts
  readonly CASE_RUN_DIR=${CASE_ROOT}/tests/${run}/run
  readonly PELAYOUT=${layout}
  readonly WALLTIME="00:20:00"
  readonly STOP_OPTION=${units}
  readonly STOP_N=${length}
  readonly REST_OPTION=${STOP_OPTION}
  readonly REST_N=${STOP_N}
  #readonly RESUBMIT=${resubmit}
  readonly RESUBMIT=0
  readonly DO_SHORT_TERM_ARCHIVING=false

else

  # Production simulation
  readonly CASE_SCRIPTS_DIR=${CASE_ROOT}/case_scripts
  readonly CASE_RUN_DIR=${CASE_ROOT}/run
  readonly PELAYOUT="L"
  readonly WALLTIME="01:00:00"
  readonly STOP_OPTION="nmonths"
  readonly STOP_N="2"
  readonly REST_OPTION="nmonths"
  readonly REST_N="1"
  readonly RESUBMIT="0"
  readonly DO_SHORT_TERM_ARCHIVING=false
fi

# Coupler history
readonly HIST_OPTION="nmonths"
readonly HIST_N="1"

# Leave empty (unless you understand what it does)
readonly OLD_EXECUTABLE=""

# --- Toggle flags for what to do ----
do_fetch_code=true
do_create_newcase=true
do_case_setup=true
do_case_build=true
do_case_submit=true

# --- Now, do the work ---

# Make directories created by this script world-readable
umask 022

# Fetch code from Github
#fetch_code

# Create case
create_newcase

# Setup
case_setup

# Build
case_build

# Configure runtime options
runtime_options

# Copy script into case_script directory for provenance
copy_script

# Submit
#case_submit

# All done
echo $'\n----- All done -----\n'

}

# =======================
# Custom user_nl settings
# =======================

user_nl() {

cat << EOF >> user_nl_eam
 nhtfrq =   0,0,0,0,0
 mfilt  = 12,12,12,12,12
 avgflag_pertape = 'A','A','A','A','A'
 fexcl1 = 'CFAD_SR532_CAL', 'LINOZ_DO3', 'LINOZ_DO3_PSC', 'LINOZ_O3CLIM', 'LINOZ_O3COL', 'LINOZ_SSO3', 'hstobie_linoz'
 fincl1 = 'extinct_sw_inp','extinct_lw_bnd7','extinct_lw_inp','CLD_CAL', 'TREFMNAV', 'TREFMXAV'

 fincl2 = 'FLUT','PRECT','TREFHT','TREFHTMN:M','TREFHTMX:X','QREFHT','TS','PS','TMQ','TUQ','TVQ','TOZ', 'FLDS', 'FLNS', 'FSDS', 'FSNS', 'SHFLX', 'LHFLX', 'TGCLDCWP', 'TGCLDIWP', 'TGCLDLWP', 'CLDTOT', 'FSNT', 'FLNT'

 fincl3 = 'FLNS','FLDS','FSNS','FSNT','FSNTOA','FSUTOA','FSDS','FUS','FDS','FSNTOAC','FSUTOAC','FSNTC','FSNSC','FSDSC','FDS_DIR','FNS', 'FLDSC','FLNS','FLNT', 'FLUT','FLUTC','FLNTC','LWCF','FDL','FNL','FUL','FNLC','SOLIN','SOLSD','SOLLD','SOLS','SOLL','SOLSDSYM','SOLLDSYM','SOLSSYM','SOLLSYM'


 fincl4 = 'TS','T1000','T975','T950','T925','T900','T850','QRS','QRL','TAP','UAP','VAP','QAP','T8501000','T9251000','TREFHT','TREFHTMN:M','TREFHTMX:X'


 fincl5= 'OMEGA1000','OMEGA975','OMEGA950','OMEGA925','OMEGA900','OMEGA850','U1000','U975','U950','U925','U900','U850','V1000','V975','V950','V925','V900','V850'



! Additional retuning
 clubb_tk1 = 268.15D0
 gw_convect_hcf = 10.0
EOF

cat << EOF >> user_nl_elm
 hist_dov2xy = .true.,.true.
 hist_fincl2 = 'H2OSNO', 'FSNO', 'QRUNOFF', 'QSNOMELT', 'FSNO_EFF', 'SNORDSL', 'SNOW', 'FSDS', 'FSR', 'FLDS', 'FIRE', 'FIRA','H2OSFC','FH2OSFC'
 hist_fincl3 = 'FSDSVD','FSDSVI','FSRVD','FSRVI','FSDSVDLN','FSDSVILN','FSRVDLN','SNOFSDSVD','SNOFSDSND','SNOFSDSVI','SNOFSDSNI','SNOFSRVD','SNOFSRND','SNOFSRVI','SNOFSRNI','FSDS'
 hist_mfilt = 1,1,1
 hist_nhtfrq = 0,0,0
 hist_avgflag_pertape = 'A','A','A'
EOF
 
 

cat << EOF >> user_nl_mosart
 rtmhist_fincl2 = 'RIVER_DISCHARGE_OVER_LAND_LIQ'
 rtmhist_mfilt = 12,12
 rtmhist_ndens = 2
 rtmhist_nhtfrq = 0,0
EOF

cat << EOF >> user_nl_mpassi
 config_am_timeseriesstatsmonthly_compute_on_startup = true
 config_am_timeseriesstatsmonthly_enable = true
 config_am_timeseriesstatsmonthly_write_on_startup = true
EOF
}

patch_mpas_streams() {

echo

}

######################################################
### Most users won't need to change anything below ###
######################################################

#-----------------------------------------------------
fetch_code() {

    if [ "${do_fetch_code,,}" != "true" ]; then
        echo $'\n----- Skipping fetch_code -----\n'
        return
    fi

    echo $'\n----- Starting fetch_code -----\n'
    local path=${CODE_ROOT}
    local repo=e3sm

    echo "Cloning $repo repository branch $BRANCH under $path"
    if [ -d "${path}" ]; then
        echo "ERROR: Directory already exists. Not overwriting"
        exit 20
    fi
    mkdir -p ${path}
    pushd ${path}

    # This will put repository, with all code
    git clone git@github.com:E3SM-Project/${repo}.git .

    # Setup git hooks
    rm -rf .git/hooks
    git clone git@github.com:E3SM-Project/E3SM-Hooks.git .git/hooks
    git config commit.template .git/hooks/commit.template

    # Check out desired branch
    git checkout ${BRANCH}

    # Custom addition
    if [ "${CHERRY}" != "" ]; then
        echo ----- WARNING: adding git cherry-pick -----
        for commit in "${CHERRY[@]}"
        do
            echo ${commit}
            git cherry-pick ${commit}
        done
        echo -------------------------------------------
    fi

    # Bring in all submodule components
    git submodule update --init --recursive

    popd
}

#-----------------------------------------------------
create_newcase() {

    if [ "${do_create_newcase,,}" != "true" ]; then
        echo $'\n----- Skipping create_newcase -----\n'
        return
    fi

    echo $'\n----- Starting create_newcase -----\n'

	if [[ -z "$CASE_GROUP" ]]; then
		${CODE_ROOT}/cime/scripts/create_newcase \
			--case ${CASE_NAME} \
			--output-root ${CASE_ROOT} \
			--script-root ${CASE_SCRIPTS_DIR} \
			--handle-preexisting-dirs u \
			--compset ${COMPSET} \
			--res ${RESOLUTION} \
			--machine ${MACHINE} \
			--project ${PROJECT} \
			--walltime ${WALLTIME} \
			--pecount ${PELAYOUT} \
			
	else
		${CODE_ROOT}/cime/scripts/create_newcase \
			--case ${CASE_NAME} \
			--case-group ${CASE_GROUP} \
			--output-root ${CASE_ROOT} \
			--script-root ${CASE_SCRIPTS_DIR} \
			--handle-preexisting-dirs u \
			--compset ${COMPSET} \
			--res ${RESOLUTION} \
			--machine ${MACHINE} \
			--project ${PROJECT} \
			--walltime ${WALLTIME} \
			--pecount ${PELAYOUT} \
			
	fi
	

    if [ $? != 0 ]; then
      echo $'\nNote: if create_newcase failed because sub-directory already exists:'
      echo $'  * delete old case_script sub-directory'
      echo $'  * or set do_newcase=false\n'
      exit 35
    fi

}

#-----------------------------------------------------
case_setup() {

    if [ "${do_case_setup,,}" != "true" ]; then
        echo $'\n----- Skipping case_setup -----\n'
        return
    fi

    echo $'\n----- Starting case_setup -----\n'
    pushd ${CASE_SCRIPTS_DIR}

    # Setup some CIME directories
    ./xmlchange EXEROOT=${CASE_BUILD_DIR}
    ./xmlchange RUNDIR=${CASE_RUN_DIR}

    # Short term archiving
    ./xmlchange DOUT_S=${DO_SHORT_TERM_ARCHIVING^^}
    ./xmlchange DOUT_S_ROOT=${CASE_ARCHIVE_DIR}


    #export NPROCS_ATM=2700
    #export NPROCS_LND=2700
    #export NPROCS_ROF=2700
    #export NPROCS_ICE=2700
    #export NPROCS_OCN=2700
    #export NPROCS_WAV=4
    #export NPROCS_CPL=2700
    #export NPROCS_GLC=4
    #export NPROCS_ESP=4
    #export NPROCS_IAC=4

    #./xmlchange  --file env_mach_pes.xml  --id PSTRID_CPL  --val 1
    #./xmlchange --file env_mach_pes.xml  --id NTASKS_CPL  --val $NPROCS_CPL
    #./xmlchange --file env_mach_pes.xml  --id NTASKS_ATM  --val $NPROCS_ATM
    #./xmlchange --file env_mach_pes.xml  --id NTASKS_LND  --val $NPROCS_LND
    #./xmlchange --file env_mach_pes.xml  --id NTASKS_ROF  --val $NPROCS_ROF
    #./xmlchange --file env_mach_pes.xml  --id NTASKS_ICE  --val $NPROCS_ICE
    #./xmlchange --file env_mach_pes.xml  --id NTASKS_OCN  --val $NPROCS_OCN
    #./xmlchange --file env_mach_pes.xml  --id NTASKS_GLC  --val $NPROCS_GLC
    #./xmlchange --file env_mach_pes.xml  --id NTASKS_WAV  --val $NPROCS_WAV
    #./xmlchange --file env_mach_pes.xml  --id NTASKS_ESP  --val $NPROCS_ESP
    #./xmlchange --file env_mach_pes.xml  --id NTASKS_IAC  --val $NPROCS_IAC

    

    # Turn on RRTMGP JPT
    ./xmlchange --append CAM_CONFIG_OPTS='-rad rrtmgp' # JPT - Use RRTMGP INSTEAD     

    
    # Build with COSP, except for a data atmosphere (datm)
    if [ `./xmlquery --value COMP_ATM` == "datm"  ]; then
      echo $'\nThe specified configuration uses a data atmosphere, so cannot activate COSP simulator\n'
    else
      echo $'\nConfiguring E3SM to use the COSP simulator\n'
      ./xmlchange --id CAM_CONFIG_OPTS --append --val='-cosp'
    fi

    # Extracts input_data_dir in case it is needed for user edits to the namelist later
    local input_data_dir=`./xmlquery DIN_LOC_ROOT --value`

    # Custom user_nl
    user_nl

    # Finally, run CIME case.setup
    ./case.setup --reset

    popd
}

#-----------------------------------------------------
case_build() {

    pushd ${CASE_SCRIPTS_DIR}

    # do_case_build = false
    if [ "${do_case_build,,}" != "true" ]; then

        echo $'\n----- case_build -----\n'

        if [ "${OLD_EXECUTABLE}" == "" ]; then
            # Ues previously built executable, make sure it exists
            if [ -x ${CASE_BUILD_DIR}/e3sm.exe ]; then
                echo 'Skipping build because $do_case_build = '${do_case_build}
            else
                echo 'ERROR: $do_case_build = '${do_case_build}' but no executable exists for this case.'
                exit 297
            fi
        else
            # If absolute pathname exists and is executable, reuse pre-exiting executable
            if [ -x ${OLD_EXECUTABLE} ]; then
                echo 'Using $OLD_EXECUTABLE = '${OLD_EXECUTABLE}
                cp -fp ${OLD_EXECUTABLE} ${CASE_BUILD_DIR}/
            else
                echo 'ERROR: $OLD_EXECUTABLE = '$OLD_EXECUTABLE' does not exist or is not an executable file.'
                exit 297
            fi
        fi
        echo 'WARNING: Setting BUILD_COMPLETE = TRUE.  This is a little risky, but trusting the user.'
        ./xmlchange BUILD_COMPLETE=TRUE

    # do_case_build = true
    else

        echo $'\n----- Starting case_build -----\n'

        # Turn on debug compilation option if requested
        if [ "${DEBUG_COMPILE^^}" == "TRUE" ]; then
            ./xmlchange DEBUG=${DEBUG_COMPILE^^}
        fi

        # Run CIME case.build
        ./case.build

        # Some user_nl settings won't be updated to *_in files under the run directory
        # Call preview_namelists to make sure *_in and user_nl files are consistent.
        ./preview_namelists

    fi

    popd
}

#-----------------------------------------------------
runtime_options() {

    echo $'\n----- Starting runtime_options -----\n'
    pushd ${CASE_SCRIPTS_DIR}

    # Set simulation start date
    ./xmlchange RUN_STARTDATE=${START_DATE}

    # Segment length
    ./xmlchange STOP_OPTION=${STOP_OPTION,,},STOP_N=${STOP_N}

    # Restart frequency
    ./xmlchange REST_OPTION=${REST_OPTION,,},REST_N=${REST_N}

    # Coupler history
    ./xmlchange HIST_OPTION=${HIST_OPTION,,},HIST_N=${HIST_N}

    # Coupler budgets (always on)
    ./xmlchange BUDGETS=TRUE

    # Set resubmissions
    if (( RESUBMIT > 0 )); then
        ./xmlchange RESUBMIT=${RESUBMIT}
    fi

    # Run type
    # Start from default of user-specified initial conditions
    if [ "${MODEL_START_TYPE,,}" == "initial" ]; then
        ./xmlchange RUN_TYPE="startup"
        ./xmlchange CONTINUE_RUN="FALSE"

    # Continue existing run
    elif [ "${MODEL_START_TYPE,,}" == "continue" ]; then
        ./xmlchange CONTINUE_RUN="TRUE"

    elif [ "${MODEL_START_TYPE,,}" == "branch" ] || [ "${MODEL_START_TYPE,,}" == "hybrid" ]; then
        ./xmlchange RUN_TYPE=${MODEL_START_TYPE,,}
        ./xmlchange GET_REFCASE=${GET_REFCASE}
	./xmlchange RUN_REFDIR=${RUN_REFDIR}
        ./xmlchange RUN_REFCASE=${RUN_REFCASE}
        ./xmlchange RUN_REFDATE=${RUN_REFDATE}
        echo 'Warning: $MODEL_START_TYPE = '${MODEL_START_TYPE}
	echo '$RUN_REFDIR = '${RUN_REFDIR}
	echo '$RUN_REFCASE = '${RUN_REFCASE}
	echo '$RUN_REFDATE = '${START_DATE}

    else
        echo 'ERROR: $MODEL_START_TYPE = '${MODEL_START_TYPE}' is unrecognized. Exiting.'
        exit 380
    fi

    # Patch mpas streams files
    patch_mpas_streams

    popd
}

#-----------------------------------------------------
case_submit() {

    if [ "${do_case_submit,,}" != "true" ]; then
        echo $'\n----- Skipping case_submit -----\n'
        return
    fi

    echo $'\n----- Starting case_submit -----\n'
    pushd ${CASE_SCRIPTS_DIR}

    # Run CIME case.submit
    ./case.submit

    popd
}

#-----------------------------------------------------
copy_script() {

    echo $'\n----- Saving run script for provenance -----\n'

    local script_provenance_dir=${CASE_SCRIPTS_DIR}/run_script_provenance
    mkdir -p ${script_provenance_dir}
    local this_script_name=`basename $0`
    local script_provenance_name=${this_script_name}.`date +%Y%m%d-%H%M%S`
    cp -vp ${this_script_name} ${script_provenance_dir}/${script_provenance_name}

}

#-----------------------------------------------------
# Silent versions of popd and pushd
pushd() {
    command pushd "$@" > /dev/null
}
popd() {
    command popd "$@" > /dev/null
}

# Now, actually run the script
#-----------------------------------------------------
main
