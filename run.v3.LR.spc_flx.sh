#!/bin/bash -fe

# E3SM Coupled Model Group run_e3sm script template.
#
# Bash coding style inspired by:
# http://kfirlavi.herokuapp.com/blog/2012/11/14/defensive-bash-programming

# TO DO:
# - custom pelayout

main() {

# For debugging, uncomment line below
#set -x

# --- Configuration flags ----

# Machine and project
readonly MACHINE=pm-cpu
# BEFORE RUNNING:  CHANGE this to your project
readonly PROJECT="e3sm"

# Simulation
#readonly COMPSET="WCYCL1850NS"
readonly COMPSET="WCYCL1850"
readonly RESOLUTION="ne30pg2_r05_IcoswISC30E3r5"
#readonly RESOLUTION="ne4pg2_oQU480"
# BEFORE RUNNING : CHANGE the following CASE_NAME to desired value
readonly CASE_NAME="WCYCL1850_spc_alb"
#readonly NL_MAPS=false
# If this is part of a simulation campaign, ask your group lead about using a case_group label
# readonly CASE_GROUP=""

# Code and compilation
# BEFORE RUNNING: CHANGE CHECKOUT to date string like 20240301
readonly CHECKOUT="20240305"
readonly BRANCH="v3.0.0"
readonly CHERRY=( )
readonly DEBUG_COMPILE=False

# Run options
readonly MODEL_START_TYPE="hybrid"  # 'initial', 'continue', 'branch', 'hybrid'
readonly START_DATE="0001-01-01"

# Additional options for 'branch' and 'hybrid'
readonly GET_REFCASE=TRUE
readonly RUN_REFDIR="/pscratch/sd/j/jtolento/LANL/chrysalis_rst/"
readonly RUN_REFCASE="20231209.v3.LR.piControl-spinup.chrysalis"
readonly RUN_REFDATE="2001-01-01"

# Set paths
readonly CASE_ROOT="${SCRATCH}/LANL/${CASE_NAME}"
readonly CODE_ROOT="${HOME}/E3SM_spc_alb"
# Sub-directories
readonly CASE_BUILD_DIR=${CASE_ROOT}/build
readonly CASE_ARCHIVE_DIR=${CASE_ROOT}/archive

# Define type of run
#  short tests: 'XS_2x5_ndays', 'XS_1x10_ndays', 'S_1x10_ndays',
#               'M_1x10_ndays', 'M2_1x10_ndays', 'M80_1x10_ndays', 'L_1x10_ndays'
#  or 'production' for full simulation
readonly run="production"

if [ "${run}" != "production" ]; then
  echo "setting up Short test simulations: ${run}"
  # Short test simulations
  tmp=($(echo $run | tr "_" " "))
  layout=${tmp[0]}
  units=${tmp[2]}
  resubmit=$(( ${tmp[1]%%x*} -1 ))
  length=${tmp[1]##*x}

  readonly CASE_SCRIPTS_DIR=${CASE_ROOT}/tests/${run}/case_scripts
  readonly CASE_RUN_DIR=${CASE_ROOT}/tests/${run}/run
  readonly PELAYOUT=${layout}
  readonly WALLTIME="0:30:00"
  #readonly STOP_OPTION=${units}
  #readonly STOP_N=${length}
  readonly STOP_OPTION=ndays
  readonly STOP_N=2
  readonly REST_OPTION=${STOP_OPTION}
  readonly REST_N=2
  readonly RESUBMIT=${resubmit}
  readonly DO_SHORT_TERM_ARCHIVING=false
else
  # Production simulation
  readonly CASE_SCRIPTS_DIR=${CASE_ROOT}/case_scripts
  readonly CASE_RUN_DIR=${CASE_ROOT}/run
  readonly PELAYOUT="custom-22"
  readonly WALLTIME="12:00:00"
  readonly STOP_OPTION="nyears"
  readonly STOP_N="5"
  readonly REST_OPTION="nmonths"
  readonly REST_N="6"
  readonly RESUBMIT="6"
  readonly DO_SHORT_TERM_ARCHIVING=false
fi

# Coupler history
readonly HIST_OPTION="nyears"
readonly HIST_N="1"

# Leave empty (unless you understand what it does)
readonly OLD_EXECUTABLE=""

# --- Toggle flags for what to do ----
do_fetch_code=false
do_create_newcase=true
do_case_setup=true
do_case_build=true
do_case_submit=true

# --- Now, do the work ---

# Make directories created by this script world-readable
umask 022

# Fetch code from Github
fetch_code

# Create case
create_newcase

# Custom PE layout
#custom_pelayout

# Setup
case_setup

# Build
case_build

# Configure runtime options
runtime_options

# Copy script into case_script directory for provenance
copy_script

# Submit
case_submit

# All done
echo $'\n----- All done -----\n'

}

# =======================
# Custom user_nl settings
# =======================

user_nl() {

cat << EOF >> user_nl_eam
 spectralflux  = .true.
 nhtfrq =   0,0,0,0,0,0
 mfilt  = 1,1,1,1,1,1
 avgflag_pertape = 'A','A','A','A','A','A' 
 fexcl1 = 'LINOZ_DO3', 'LINOZ_DO3_PSC', 'LINOZ_O3CLIM', 'LINOZ_O3COL', 'LINOZ_SSO3', 'hstobie_linoz'
 fincl1 = 'extinct_sw_inp','extinct_lw_bnd7','extinct_lw_inp','TREFMNAV','TREFMXAV' 
 fincl2 = 'FLUT','PRECT','TREFHT','TREFHTMN:M','TREFHTMX:X','QREFHT','TS','PS','TMQ','TUQ','TVQ','TOZ', 'FLDS', 'FLNS', 'FSDS', 'FSNS', 'SHFLX', 'LHFLX', 'TGCLDCWP', 'TGCLDIWP', 'TGCLDLWP', 'CLDTOT', 'FSNT', 'FLNT'
 fincl3 = 'FLNS','FLDS','FSNS','FSNT','FSNTOA','FSUTOA','FSDS','SOLIN','SOLL','SOLLD','SOLS','SOLSD','FUS','FDS'
 fincl4 = 'TS','T925','T850','QRS','TAP','UAP','VAP','QAP','T8501000','T9251000','TREFHT','TREFHTMN:M','TREFHTMX:X','T'
 fincl5= 'OMEGA1000','OMEGA975','OMEGA950','OMEGA925','OMEGA900','OMEGA850','U1000','U975','U950','U925','U900','U850','V1000','V975','V950','V925','V900','V850'
 fincl6 = 'ASDIR','ALDIR','ASDIF','ALDIF','FLNS','FLDS','FSNS','FSNT','FSNTOA','FSUTOA','FSDS','SOLIN','SOLL','SOLLD','SOLS','SOLSD','ALB_NIR_A_DIR','ALB_NIR_B_DIR','ALB_NIR_C_DIR','ALB_NIR_D_DIR','ALB_NIR_E_DIR','ALB_NIR_F_DIR','ALB_NIR_G_DIR','ALB_NIR_A_DIF','ALB_NIR_B_DIF','ALB_NIR_C_DIF','ALB_NIR_D_DIF','ALB_NIR_E_DIF','ALB_NIR_F_DIF','ALB_NIR_G_DIF','NIR_A_DIR','NIR_B_DIR','NIR_C_DIR','NIR_D_DIR','NIR_E_DIR','NIR_F_DIR','NIR_G_DIR','NIR_A_DIF','NIR_B_DIF','NIR_C_DIF','NIR_D_DIF','NIR_E_DIF','NIR_F_DIF','NIR_G_DIF','SNOWFRAC','SD_BOA','SD_TOA','SU_TOA','SU_BOA'

EOF

cat << EOF >> user_nl_elm
 use_snicar_ad = true
 hist_dov2xy = .true.,.true.
 hist_fincl2 = 'H2OSNO', 'ALBD', 'ALBGRD', 'ALBGRI', 'ALBI', 'SNO_EXISTENCE', 'SNORDSL', 'QFLX_SUB_SNOW', 'QFLX_RAIN_GRND', 'QFLX_SNOW_GRND', 'LWdown', 'Tair', 'PSurf', 'COSZEN', 'QICE'
 hist_fincl3='H2OSNO', 'FSNO', 'FSNO_EFF', 'H2OSFC', 'FH2OSFC', 'SNORDSL', 'SNO_BW', 'SNO_GS', 'SNO_Z', 'SNO_LIQH2O', 'SNO_ICE', 'SOILICE_ICE', 'SOILLIQ_ICE', 'SNO_T', 'TSOI_ICE', 'TH2OSFC', 'SNO_TK', 'SNO_ABS', 'SNO_EXISTENCE'
 hist_fincl4='SNOW_DEPTH', 'H2OSNO', 'SNO_T'
 hist_fincl5 = 'FSDSVD','FSDSVI','FSRVD','FSRVI','FSDSVDLN','FSDSVILN','FSRVDLN','SNOFSDSVD','SNOFSDSND','SNOFSDSVI','SNOFSDSNI','SNOFSRVD','SNOFSRND','SNOFSRVI','SNOFSRNI','FSDS','FSDSNI','FSDSND','FSRND','FSRNI'
 hist_nhtfrq= 0,0,0,0,0
 hist_mfilt= 1,1, 1, 1,1
 hist_avgflag_pertape= 'A', 'A','A','A','A'

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
			--pecount ${PELAYOUT}
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
			--pecount ${PELAYOUT}
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

    # PE Layout
    # 21 nodes - ~10 sy/wd  
    export NPROCS_ATM=1800
    export NPROCS_LND=768
    export NPROCS_ROF=768
    export NPROCS_ICE=1152
    export NPROCS_OCN=768
    export NPROCS_CPL=1920
    export NPROCS_WAV=1
    export NPROCS_GLC=1
    export NPROCS_ESP=1
    export NPROCS_IAC=1

    ./xmlchange --file env_mach_pes.xml  --id PSTRID_CPL  --val 1
    ./xmlchange --file env_mach_pes.xml  --id NTASKS_CPL  --val $NPROCS_CPL
    ./xmlchange --file env_mach_pes.xml  --id NTASKS_ATM  --val $NPROCS_ATM
    ./xmlchange --file env_mach_pes.xml  --id NTASKS_LND  --val $NPROCS_LND
    ./xmlchange --file env_mach_pes.xml  --id NTASKS_ROF  --val $NPROCS_ROF
    ./xmlchange --file env_mach_pes.xml  --id NTASKS_ICE  --val $NPROCS_ICE
    ./xmlchange --file env_mach_pes.xml  --id NTASKS_OCN  --val $NPROCS_OCN
    ./xmlchange --file env_mach_pes.xml  --id NTASKS_GLC  --val $NPROCS_GLC
    ./xmlchange --file env_mach_pes.xml  --id NTASKS_WAV  --val $NPROCS_WAV
    ./xmlchange --file env_mach_pes.xml  --id NTASKS_ESP  --val $NPROCS_ESP
    ./xmlchange --file env_mach_pes.xml  --id NTASKS_IAC  --val $NPROCS_IAC

    ./xmlchange LND_ROOTPE=1152
    ./xmlchange ROF_ROOTPE=1152
    ./xmlchange OCN_ROOTPE=1920
    
    ./xmlchange ATM2LND_FMAPNAME_NONLINEAR="idmap_ignore" 

    #./xmlchange --append CAM_CONFIG_OPTS='-rad rrtmgp' # JPT - Use RRTMGP INSTEAD 
    # Build with COSP, except for a data atmosphere (datm)
    if [ `./xmlquery --value COMP_ATM` == "datm"  ]; then
      echo $'\nThe specified configuration uses a data atmosphere, so cannot activate COSP simulator\n'
    else
      echo $'\nConfiguring E3SM to use the COSP simulator\n'
      #./xmlchange --id CAM_CONFIG_OPTS --append --val='-cosp'
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
	 echo $'\n----- Preview namelists -----\n'
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
    #./xmlchange --file env_workflow.xml --id JOB_QUEUE --val debug
    ./case.submit -a="--mail-type=ALL --mail-user=$USER@nersc.gov --requeue"

    popd
}

#-----------------------------------------------------
copy_script() {
    echo $'\n----- Saving run script for provenance -----\n'
    local script_provenance_dir=${CASE_SCRIPTS_DIR}/run_script_provenance
    mkdir -p ${script_provenance_dir}
    local this_script_name=$( basename -- "$0"; )
    local this_script_dir=$( dirname -- "$0"; )
    local script_provenance_name=${this_script_name}.`date +%Y%m%d-%H%M%S`
    cp -vp "${this_script_dir}/${this_script_name}" ${script_provenance_dir}/${script_provenance_name}
}


# =====================================================
# Custom PE layout: custom-N where N is number of nodes
# =====================================================

custom_pelayout(){

if [[ ${PELAYOUT} == custom-* ]];
then
    echo $'\n CUSTOMIZE PROCESSOR CONFIGURATION:'

    # Number of cores per node (machine specific)
    if [ "${MACHINE}" == "chrysalis" ]; then
        ncore=64
        hthrd=2  # hyper-threading
    else
        echo 'ERROR: MACHINE = '${MACHINE}' is not supported for current custom PE layout setting.'
        exit 400
    fi

    # Extract number of nodes
    tmp=($(echo ${PELAYOUT} | tr "-" " "))
    nnodes=${tmp[1]}

    # Applicable to all custom layouts
    pushd ${CASE_SCRIPTS_DIR}

    ./xmlchange NTASKS=$(( $nnodes * $ncore ))
    ./xmlchange NTHRDS=1
    ./xmlchange ROOTPE=0
    ./xmlchange MAX_MPITASKS_PER_NODE=$ncore
    ./xmlchange MAX_TASKS_PER_NODE=$(( $ncore * $hthrd))

    popd

fi

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
