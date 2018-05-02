

declare QUAST_FILES
declare QUAST_LABELS
declare QUAST_LABELS_ALTREF
declare QUAST_FILES_ALTREF

# Variable definition
PROJECT=`echo $1 | cut -f1 -d'_'`
LOG_FILE="$3/${PROJECT}_logger/AMALGAM_$PROJECT.log"
COMPARISON_REPO="$3/$2/$1.comparison/"

# Find availables files for Quast analysis 
# SHORT_ASSEMBLER_LIST=(spades abyss32 abyss64 abyss96 idba_ud)
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


# Make Quast analysis for available files 
echo -e "\n[INFO] ["$1"] Start assemblies comparison with Quast and new reference\n" >> ${LOG_FILE}
quast.py -R $4 -o ${COMPARISON_REPO} --labels ${QUAST_LABELS[@]:1} ${QUAST_FILES} 
echo -e "\n[INFO] ["$1"] End of assemblies comparison with Quast and new reference\n" >> ${LOG_FILE}