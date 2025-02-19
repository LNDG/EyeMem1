#!/bin/bash

## Create Mean PLS datamats

source pls_config.sh

for SID in $SubjectID; do
	
	echo "#PBS -N batch_plsgui_${SID}" 				>> job # job name 
	echo "#PBS -l walltime=01:00:0" 					>> job # time until job is killed
	echo "#PBS -l mem=2gb" 							>> job # books 10gb RAM for the job --> 1 CPU hat normalerweise 4gb
	#echo "#PBS -l nodes=1:ppn=16" 					>> job 
	#echo "#PBS -m ae" 								>> job # email notification on abort/end   -n no notification 
	echo "#PBS -o ${LogPath}"						>> job # write (error) log to log folder 
	echo "#PBS -e ${LogPath}" 						>> job 

	echo "cd ${SDPLS}" 							>> job   # job output dir 

	echo "${ScriptsPath}/run_replace_meanDatamat_with_SD.sh /opt/matlab/R2014b" 		>> job 
	
	echo "chmod -R 770 SD_${SID}_BfMRIsessiondata.mat" 												>> job
 
	# submit job
	qsub job  
	rm job

done 