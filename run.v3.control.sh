#!/bin/bash -fe

# E3SM Coupled Model Group run_e3sm script template.
#
# Bash coding style inspired by:
# http://kfirlavi.herokuapp.com/blog/2012/11/14/defensive-bash-programming

main() {

# For debugging, uncomment libe below
#set -x

# --- Configuration flags ----

# Machine and project
readonly MACHINE=pm-cpu
readonly PROJECT="e3sm"

# Simulation
readonly COMPSET="WCYCL1850"
readonly RESOLUTION="ne30pg2_r05_IcoswISC30E3r5"
#readonly NL_MAPS=true   ### nonlinear maps for tri-grid
readonly CASE_NAME="control"

# Code and compilation
readonly CHECKOUT="latest"
readonly BRANCH="master"  #
readonly CHERRY=( )
readonly DEBUG_COMPILE=true

# Run options
readonly MODEL_START_TYPE="initial"  # 'initial', 'continue', 'branch', 'hybrid'
readonly START_DATE="1850-01-01"

# Additional options for 'branch' and 'hybrid'
readonly GET_REFCASE=FALSE

# Set paths
readonly CODE_ROOT="/global/homes/j/jtolento/E3SMv3/${CASE_NAME}/code/${CHECKOUT}"
readonly CASE_ROOT="${SCRATCH}/LANL/${CASE_NAME}"

# Sub-directories
readonly CASE_BUILD_DIR=${CASE_ROOT}/build
readonly CASE_ARCHIVE_DIR=${CASE_ROOT}/archive

# Uncomment lines below only for priority partition on chrysalis
#readonly CHARGE_ACCOUNT="priority"
#readonly JOB_QUEUE="priority"

# Define type of run
#  short tests: 'XS_1x10_ndays', 'XS_2x5_ndays', 'S_1x10_ndays', 'M_1x10_ndays', 'L_1x10_ndays'
#  or 'production' for full simulation

readonly run='S_1x10_ndays'
#readonly run='S_2x5_ndays'
#readonly run='custom-52_1x10_ndays'
#readonly run='custom-104_1x10_ndays'

#readonly run='production'

if [[ "${run}" != "production" ]]; then
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
  readonly STOP_OPTION=${units}
  readonly STOP_N=${length}
  readonly REST_OPTION=${STOP_OPTION}
  readonly REST_N=${STOP_N}
  readonly RESUBMIT=${resubmit}
  readonly DO_SHORT_TERM_ARCHIVING=false

else
  echo "setting up ${run}"
  # Production simulation
  readonly CASE_SCRIPTS_DIR=${CASE_ROOT}/case_scripts
  readonly CASE_RUN_DIR=${CASE_ROOT}/run
  readonly PELAYOUT="M"
  readonly WALLTIME="48:00:00"
  readonly STOP_OPTION="nyears"
  readonly STOP_N="40"
  readonly REST_OPTION="nyears"
  readonly REST_N="1"
  readonly RESUBMIT="9"
  readonly DO_SHORT_TERM_ARCHIVING=false
fi

# Coupler history 
readonly HIST_OPTION="nsteps"
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

EOF

cat << EOF >> user_nl_elm

EOF

cat << EOF >> user_nl_mpaso


EOF

}

# =====================================
# Customize MPAS stream files if needed
# =====================================

patch_mpas_streams() {

echo

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
    ./xmlchange NTASKS=1
    ./xmlchange NTHRDS=1
    ./xmlchange ROOTPE=0
    ./xmlchange MAX_MPITASKS_PER_NODE=$ncore
    ./xmlchange MAX_TASKS_PER_NODE=$(( $ncore * $hthrd))

    # Layout-specific customization
    if [ "${nnodes}" == "104" ]; then

       echo Using custom 104 nodes layout

       ### Current defaults for L
      ./xmlchange CPL_NTASKS=5440
      ./xmlchange ATM_NTASKS=5440
      ./xmlchange OCN_NTASKS=1216
      ./xmlchange OCN_ROOTPE=5440

      ### Added by Xue for tri-grid
      ./xmlchange LND_NTASKS=1088
      ./xmlchange ROF_NTASKS=1088
      ./xmlchange ICE_NTASKS=4352
      ./xmlchange LND_ROOTPE=4352
      ./xmlchange ROF_ROOTPE=4352

    elif [ "${nnodes}" == "52" ]; then

       echo Using custom 52 nodes layout

      ./xmlchange CPL_NTASKS=2720
      ./xmlchange ATM_NTASKS=2720
      ./xmlchange OCN_NTASKS=608
      ./xmlchange OCN_ROOTPE=2720

      ### Added by Xue for tri-grid
      ./xmlchange LND_NTASKS=544
      ./xmlchange ROF_NTASKS=544
      ./xmlchange ICE_NTASKS=2176
      ./xmlchange LND_ROOTPE=2176
      ./xmlchange ROF_ROOTPE=2176

    else

       echo 'ERRROR: unsupported layout '${PELAYOUT}
       exit 401

    fi

    popd

fi

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
    local repo=E3SM

    echo "Cloning $repo repository branch $BRANCH under $path"
    if [ -d "${path}" ]; then
        echo "ERROR: Directory already exists. Not overwriting"
        exit 20
    fi
    mkdir -p ${path}
    pushd ${path}

    # This will put repository, with all code
    git clone git@github.com:E3SM-Project/${repo}.git .

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

    if [[ ${PELAYOUT} == custom-* ]];
    then
        layout="M" # temporary placeholder for create_newcase
    else
        layout=${PELAYOUT}

    fi
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
        --pecount ${layout}

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
    ./xmlchange --append CAM_CONFIG_OPTS='-rad rrtmgp' 
    # Turn on ELM BGC
    ./xmlchange --file env_run.xml --id ELM_BLDNML_OPTS  --val "-bgc bgc -nutrient cnp -nutrient_comp_pathway rd  -soil_decomp ctc -methane"

    # Build with COSP, except for a data atmosphere (datm)
    if [ `./xmlquery --value COMP_ATM` == "datm"  ]; then 
      echo $'\nThe specified configuration uses a data atmosphere, so cannot activate COSP simulator\n'
    else
      echo $'\nConfiguring E3SM to use the COSP simulator\n'
      ./xmlchange --id CAM_CONFIG_OPTS --append --val='-cosp'
    fi

    # Extracts input_data_dir in case it is needed for user edits to the namelist later
    local input_data_dir=`./xmlquery DIN_LOC_ROOT --value`

    # Enable non-linear mapping
    if $NL_MAPS ; then
        echo "Setting nonlinear maps"
        alg=trfvnp2

        # Atm -> srf maps
        a2l=cpl/gridmaps/ne30pg2/map_ne30pg2_to_r05_${alg}.230516.nc
        a2o=cpl/gridmaps/ne30pg2/map_ne30pg2_to_IcoswISC30E3r5_trfvnp2.20231121.nc
        ./xmlchange ATM2LND_FMAPNAME_NONLINEAR=$a2l
        ./xmlchange ATM2ROF_FMAPNAME_NONLINEAR=$a2l
        ./xmlchange ATM2OCN_FMAPNAME_NONLINEAR=$a2o
    fi


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

    fi

    # Some user_nl settings won't be updated to *_in files under the run directory
    # Call preview_namelists to make sure *_in and user_nl files are consistent.
    echo $'\n----- Preview namelists -----\n'
    ./preview_namelists

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

    # Change account and partition (if requested by user)
    if [[ -v CHARGE_ACCOUNT ]]; then
        echo Modifying CHARGE_ACCOUNT and PROJECT to ${CHARGE_ACCOUNT}
        ./xmlchange --file env_workflow.xml --id CHARGE_ACCOUNT --val ${CHARGE_ACCOUNT}
        ./xmlchange --file env_workflow.xml --id PROJECT --val ${CHARGE_ACCOUNT}
    fi
    if [[ -v JOB_QUEUE ]]; then
        echo Modifying JOB_QUEUE to ${JOB_QUEUE}
        ./xmlchange --file env_workflow.xml --id JOB_QUEUE --val ${JOB_QUEUE}
    fi

    # Run CIME case.submit
    ./xmlchange --file env_workflow.xml --id JOB_QUEUE
    ./case.submit -a="--mail-type=ALL --mail-user=$USER@nersc.gov --requeue"
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
