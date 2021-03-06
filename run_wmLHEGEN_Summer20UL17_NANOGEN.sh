#!/bin/bash
i=1
# GRIDPACK=${!i}; i=$((i+1))
FRAGMENT=${!i}; i=$((i+1))
NEVENTS=${!i}; i=$((i+1))
NTHREADS=${!i}; i=$((i+1))
OUTPATH=${!i}; i=$((i+1))

# echo "Gridpack: ${GRIDPACK}"
echo "Fragment: ${FRAGMENT}"
echo "Nevents: ${NEVENTS}"
echo "Nthreads ${NTHREADS}"
echo "Outpath: ${OUTPATH}"

source /cvmfs/cms.cern.ch/cmsset_default.sh
if [ -r CMSSW_11_2_0_pre7/src ] ; then
  echo release CMSSW_11_2_0_pre7 already exists
else
  scram p CMSSW CMSSW_11_2_0_pre7
fi
cd CMSSW_11_2_0_pre7/src
eval `scram runtime -sh`

mkdir -p Configuration/GenProduction/python/
cp ${FRAGMENT}  Configuration/GenProduction/python/
# sed -i "s/@GRIDPACK/${GRIDPACK}" Configuration/GenProduction/python/$(basename $FRAGMENT)

[ -s Configuration/GenProduction/python/$(basename $FRAGMENT) ] || exit $?;

scram b
cd ../../
seed=$(date +%s)

cmsDriver.py Configuration/GenProduction/python/$(basename $FRAGMENT) \
    --fileout file:nanogen.root \
    --mc \
    --eventcontent NANOAODSIM \
    --datatier NANOAOD \
    --conditions 106X_mc2017_realistic_v6 \
    --step LHE,GEN,NANOGEN \
    --nThreads ${NTHREADS} \
    --geometry DB:Extended \
    --era Run2_2017 \
    --python_filename NANOGEN.py \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --customise_commands process.RandomNumberGeneratorService.externalLHEProducer.initialSeed="int(${seed}%100)" \
    -n ${NEVENTS} \
    --no_exec || exit $? ;

cmsRun NANOGEN.py | tee log_NANOGEN.txt

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
