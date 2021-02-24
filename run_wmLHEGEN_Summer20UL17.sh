#!/bin/bash
i=1
GRIDPACK=${!i}; i=$((i+1))
FRAGMENT=${!i}; i=$((i+1))
NEVENTS=${!i}; i=$((i+1))
NTHREADS=${!i}; i=$((i+1))
OUTPATH=${!i}; i=$((i+1))

source /cvmfs/cms.cern.ch/cmsset_default.sh
if [ -r CMSSW_10_6_18/src ] ; then
  echo release CMSSW_10_6_18 already exists
else
  scram p CMSSW CMSSW_10_6_18
fi
cd CMSSW_10_6_18/src
eval `scram runtime -sh`

mkdir -p Configuration/GenProduction/python/
cp ${FRAGMENT}  Configuration/GenProduction/python/
sed -i "s/@GRIDPACK/${GRIDPACK}" Configuration/GenProduction/python/$(basename $FRAGMENT)

[ -s Configuration/GenProduction/python/$(basename $FRAGMENT) ] || exit $?;

scram b
cd ../../
seed=$(date +%s)

cmsDriver.py Configuration/GenProduction/python/$(basename $FRAGMENT) \ 
--fileout file:wmLHEGEN.root \ 
--mc \ 
--eventcontent RAWSIM,LHE \ 
--datatier GEN,LHE \
--conditions 106X_mc2017_realistic_v6 \ 
--beamspot Realistic25ns13TeVEarly2017Collision \ 
--step LHE,GEN \ 
--nThreads ${NTHREADS} \
--geometry DB:Extended \ 
--era Run2_2017 \ 
--python_filename wmLHEGEN.py \ 
--customise Configuration/DataProcessing/Utils.addMonitoring \
--customise_commands process.source.numberEventsInLuminosityBlock="cms.untracked.uint32(1036)" \ 
--no_exec \ 
-n ${NEVENTS} || exit $? ;

cmsRun wmLHEGEN.py | tee log_wmLHEGEN.txt

OUTTAG=$(echo $JOBFEATURES | sed "s|_[0-9]*$||;s|.*_||")

if [ -z "${OUTTAG}" ]; then
    OUTTAG=$(md5sum *.root | head -1 | awk '{print $1}')
fi

echo "Using output tag: ${OUTTAG}"
mkdir -p ${OUTPATH}
for file in *.root; do 
    mv $file $OUTPATH/$(echo $file | sed "s|.root|_${OUTTAG}.root|g")
done
for file in *.txt; do 
    mv $file $OUTPATH/$(echo $file | sed "s|.root|_${OUTTAG}.txt|g")
done
