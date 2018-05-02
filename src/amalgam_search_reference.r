args <- commandArgs(TRUE)
summary_table<-args[1]
# summary_table<-"/env/export/bigtmp1/msejour/A/AMALGAM_BPK/BA_20171121-143049-030156395/BPK_BA.comparison/scaffolds-reference/summary_report_new_reference.tsv"

t<-read.table(summary_table,header=TRUE,comment.char = "",sep = "\t")
rownames(t)<-t[,1]
t[,1]<-NULL
bestN50=colnames(t)[which.max(as.numeric(t[1,]))]
bestNContigs=colnames(t)[which.min(as.numeric(t[2,]))]
if (bestNContigs == bestN50){
  toreturn<-bestN50
}else{
	NUM_NcontigsFromBestN50=t[2,bestN50]
	NUM_Ncontigs=t[2,bestNContigs]
	if (NUM_NcontigsFromBestN50 == NUM_Ncontigs){
		toreturn<-bestN50
	}else{
  		toreturn<-"Nothing"
  	}
}
cat(toreturn)
