

declare QUAST_FILES
declare QUAST_LABELS
declare QUAST_LABELS_ALTREF
declare QUAST_FILES_ALTREF

# Variable definition and create directory
PROJECT=`echo $1 | cut -f1 -d'_'`
LOG_FILE="$3/${PROJECT}_logger/AMALGAM_$PROJECT.log"
ERR_FILE="$3/${PROJECT}_logger/AMALGAM_$PROJECT.err"
RSCRIPT=`which amalgam_search_reference.r`
COMPARISON_REPO="$3/$2/$1.comparison/"
ALTREF_REPO="${COMPARISON_REPO}scaffolds-reference/"
if [[ ! -d ${ALTREF_REPO} ]];then
	mkdir -p ${ALTREF_REPO}
fi 

# Find availables files for Quast analysis 
SEQUENCE_TYPE_LIST=(contigs scaffolds grp-scaffolds)
# [Short reads assembly] Test if file exist and add in lists for Quast command line
if [[ -d $3/$2/S.$1/ ]];then 
	SHORT_ASSEMBLER_LIST=`ls $3/$2/S.$1/ | grep "spades\|abyss\|idba_ud"`
	for SEQUENCE_TYPE in ${SEQUENCE_TYPE_LIST[@]};do 
		for ASSEMBLER in ${SHORT_ASSEMBLER_LIST[@]};do
			abyssregex="abyss[[:digit:]]+"
			if [[ ${ASSEMBLER} =~ $abyssregex ]];then
				ASSEMBLER_TOOL="abyss"
			else
				ASSEMBLER_TOOL=${ASSEMBLER}
			fi
			if [[ -f $3/$2/S.$1/${ASSEMBLER}/backup/${ASSEMBLER_TOOL}_${SEQUENCE_TYPE}.fasta ]];then 
				QUAST_LABELS=${QUAST_LABELS}",S.${ASSEMBLER}_${SEQUENCE_TYPE}"
				QUAST_FILES=${QUAST_FILES}" $3/$2/S.$1/${ASSEMBLER}/backup/${ASSEMBLER_TOOL}_${SEQUENCE_TYPE}.fasta"
				if [[ ${SEQUENCE_TYPE} == "grp-scaffolds" ]];then 
					QUAST_LABELS_ALTREF=${QUAST_LABELS_ALTREF}",S.${ASSEMBLER}_${SEQUENCE_TYPE}"
					QUAST_FILES_ALTREF=${QUAST_FILES_ALTREF}" $3/$2/S.$1/${ASSEMBLER}/backup/${ASSEMBLER_TOOL}_${SEQUENCE_TYPE}.fasta"
				fi
			fi
		done
	done
fi 
# [Hybrid reads assembly] Test if file exist and add in lists for Quast command line
if [[ -d $3/$2/H.$1/ ]];then 
	HYBRID_ASSEMBLER_LIST=(spades)
	for SEQUENCE_TYPE in ${SEQUENCE_TYPE_LIST[@]};do 
		for ASSEMBLER in ${HYBRID_ASSEMBLER_LIST[@]};do
			if [[ -f $3/$2/H.$1/${ASSEMBLER}/backup/${ASSEMBLER}_${SEQUENCE_TYPE}.fasta ]];then 
				QUAST_LABELS=${QUAST_LABELS}",H.${ASSEMBLER}_${SEQUENCE_TYPE}"
				QUAST_FILES=${QUAST_FILES}" $3/$2/H.$1/${ASSEMBLER}/backup/${ASSEMBLER}_${SEQUENCE_TYPE}.fasta"
				if [[ ${SEQUENCE_TYPE} == "grp-scaffolds" ]];then 
					QUAST_LABELS_ALTREF=${QUAST_LABELS_ALTREF}",H.${ASSEMBLER}_${SEQUENCE_TYPE}"
					QUAST_FILES_ALTREF=${QUAST_FILES_ALTREF}" $3/$2/H.$1/${ASSEMBLER}/backup/${ASSEMBLER}_${SEQUENCE_TYPE}.fasta"
				fi
			fi
		done
	done
fi 
# [Long reads assembly] 
if [[ -d $3/$2/L.$1/ ]];then
	LONG_ASSEMBLER_LIST=(canu)
	for SEQUENCE_TYPE in ${SEQUENCE_TYPE_LIST[@]};do 
		for ASSEMBLER in ${LONG_ASSEMBLER_LIST[@]};do
			if [[ -f $3/$2/L.$1/${ASSEMBLER}/backup/${ASSEMBLER}_${SEQUENCE_TYPE}.fasta ]];then 
				QUAST_LABELS=${QUAST_LABELS}",L.${ASSEMBLER}_${SEQUENCE_TYPE}"
				QUAST_FILES=${QUAST_FILES}" $3/$2/L.$1/${ASSEMBLER}/backup/${ASSEMBLER}_${SEQUENCE_TYPE}.fasta"
				if [[ ${SEQUENCE_TYPE} == "grp-scaffolds" ]];then 
					QUAST_LABELS_ALTREF=${QUAST_LABELS_ALTREF}",L.${ASSEMBLER}_${SEQUENCE_TYPE}"
					QUAST_FILES_ALTREF=${QUAST_FILES_ALTREF}" $3/$2/L.$1/${ASSEMBLER}/backup/${ASSEMBLER}_${SEQUENCE_TYPE}.fasta"
				fi
			fi
		done
	done
fi 

# Make first Quast to calcul element for scafolds selection 
echo -e "\n[INFO] ["$1"] Start assemblies comparison with Quast\n" >> ${LOG_FILE}
quast.py -m 2000 -o ${ALTREF_REPO} --labels ${QUAST_LABELS_ALTREF[@]:1} ${QUAST_FILES_ALTREF}
echo -e "\n[INFO] ["$1"] End of assemblies comparison with Quast\n" >> ${LOG_FILE}
# If Quast analysis is succesful make summary file with N50 and number of contigs informations
if [[ -f ${ALTREF_REPO}/report.tsv ]];then 
	head -n 1 ${ALTREF_REPO}/report.tsv > ${ALTREF_REPO}/summary_report_new_reference.tsv
	grep "^N50" ${ALTREF_REPO}/report.tsv >> ${ALTREF_REPO}/summary_report_new_reference.tsv
	grep "^# contigs" ${ALTREF_REPO}/report.tsv | grep -v "^# contigs (" >> ${ALTREF_REPO}/summary_report_new_reference.tsv
	# grep "^# contigs" ${ALTREF_REPO}/report.tsv | grep -v "^# contigs (" | sed 's/ /_/' >> ${ALTREF_REPO}/summary_report_new_reference.tsv
	# Make R analysis to select good scaffolds
	VALUE_TEST=`R --vanilla --slave --args ${ALTREF_REPO}summary_report_new_reference.tsv < ${RSCRIPT}`
	# Condition according to result of R script
	if [[ ${VALUE_TEST} != "Nothing" ]];then 
		# Find good scaffolds file
		ASS_TYPE=`echo ${VALUE_TEST} | cut -f1 -d"."`
		ASS_NAME=`echo ${VALUE_TEST} | cut -f2 -d"." | cut -f1 -d"_"`
		# If assembler is abyss
		abyssregex="abyss[[:digit:]]+"
		if [[ ${ASS_NAME} =~ $abyssregex ]];then
			ASS_NAME_TOOL="abyss"
		else 
			ASS_NAME_TOOL=${ASS_NAME}
		fi
		# Select file path 
		FILE_FOR_REFRENCE="$3/$2/${ASS_TYPE}.$1/${ASS_NAME}/backup/${ASS_NAME_TOOL}_grp-scaffolds.fasta"
		# Select sequences greater than 2000 pb 
		awk '/^>/ {printf("%s%s\t",(N>0?"\n":""),$0);N++;next;} {printf("%s",$0);} END {printf("\n");}' ${FILE_FOR_REFRENCE} | awk -F "\t" '{printf("%d\t%s\n",length($2),$0);}' | sort -k1,1n | awk '$1 > 1999 { print $0 }' | awk '{ print $2"\n"$3} '  > ${ALTREF_REPO}/scaffolds_reference.fasta
		# Make Quast analysis with new reference dans contigs, scaffolds, and all scaffolds after gap closer (grp-scaffolds)
		echo -e "\n[INFO] ["$1"] Start assemblies comparison with Quast and new reference\n" >> ${LOG_FILE}
		quast.py --fragmented -R ${ALTREF_REPO}/scaffolds_reference.fasta -o ${COMPARISON_REPO} --labels ${QUAST_LABELS[@]:1} ${QUAST_FILES}
		echo -e "\n[INFO] ["$1"] End of assemblies comparison with Quast and new reference\n" >> ${LOG_FILE}
	else
		# No scaffolds for reference was found, Quast analysis is performed without reference.
		echo -e "[INFO] [$2] Doubt about the choice of scaffolds reference." | tee -a $LOG_FILE $ERR_FILE
		echo -e "\n[INFO] ["$1"] Start assemblies comparison with Quast without reference\n" >> ${LOG_FILE}
		quast.py -o ${COMPARISON_REPO} --labels ${QUAST_LABELS[@]:1} ${QUAST_FILES}
		echo -e "\n[INFO] ["$1"] End of assemblies comparison with Quast without reference\n" >> ${LOG_FILE}
	fi
else 
	# If there is problem in Quast analysis and no file is create 
	echo -e "[ERROR] [$2] No report file. It is not possible to find scaffolds reference." | tee -a $LOG_FILE $ERR_FILE
	echo -e "\n[INFO] ["$1"] Start assemblies comparison with Quast without reference\n" >> ${LOG_FILE}
	quast.py -o ${COMPARISON_REPO} --labels ${QUAST_LABELS[@]:1} ${QUAST_FILES}
	echo -e "\n[INFO] ["$1"] End of assemblies comparison with Quast without reference\n" >> ${LOG_FILE}
fi 
