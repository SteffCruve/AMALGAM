# Documentation for AMALGAM wrapper

## About AMALGAM wrapper

This wrapper allows to make several AMALGAM execution on several materials of one project with one commande line. It is suitable for data from Genoscope production, because it is adapted to sequencing's files hierarchy.
This script is able to execute automatically short reads and hybrid assemblies. If for one material these two types of assemblies are performed, a comparison between them is made.  

## 1. AMALGAM wrapper working

### 1.1. Conditions to start assemblies

This script is able to make AMALGAM execution on one or several material(s) of one project. In command line, these two informations are required. This script is able to find sequencing files to use in assemblies.  
Currently, two types of assemblies could be performed : assembly of short reads and hybrid assembly.

* Short reads assembly : *(only short reads)*  
&nbsp;&nbsp;&nbsp;&nbsp;Always done. This assembly is made with paire-end Illumina files comes from *RunsSolexa* repository.
* Hybrid assembly:  *(short reads and long reads)*  
&nbsp;&nbsp;&nbsp;&nbsp;This type of assembly is performed only if there is previous paire-end files **and** one associated Nanopore reads file found in *RunsNanopore* directory.


AMALGAM wrapper script search in all available repositories of Illumina and Nanopore runs and is able to select each files to assemble and make sur that :  
* There is **paired-end** files (forward and reverse) of short reads and they comes from the same sample.
* There is **at most one** reads file for long reads.

If this conditions are not fulfilled, there is a selection step with informations given in materials file. In this file, users have the possibility to specify files to used in assemblies or files to exclude to the assemblies.

#### 1.1.1. Illumina files

This type of files are required for all assemblies, **if these files are not found no assemblies will be performed**.
Paired-end Illumina files (forward  and reverse) must be found. This requirement is verified.  
If these files are found, short reads assembly is performed and these data will be used for hybrid assembly.  
If Illumina files are not found, no assembly is made and goes to the following material.  
If more than two files are found, how to choose good files to make assemblies ? In material file, it is possible to specified files to use in assemblies (included file(s))or files to not use in assemblies (excluded file(s)). According to these information this script is able to select files to assemble. After selection, if there is one paired-end files, assembly(ies) could be done, if there is no or more than one paired-end files no assembly is done. In an other case, if no files are specified for this selection no assembly is done.

#### 1.1.2. Nanopore file

This type of file is used in hybrid assembly, therefore, **if Nanopore reads are not found only hybrid assembly is not made**.
One Nanopore file is required. This script is able to find it but as for Illumina several Nanopore files should be find. So how to choose the right one ?  There is the same system as Illumina reads : selection with inclusion or exclusion of files. As previously, if one file is selected, hybrid assembly should be performed or if no or more than one file is found no hybrid assembly is made.

#### 1.1.3. About the script

This script is written in bash 4.0 and should be used in slurm clusters.  

The name of the project is specify in command line but there is two ways to specify materials to assemble :
* In command line in a list (-m *parameter see 2.1*). With this parameter it is not possible to specify included or excluded files to assemble or to specify reference file or to ask for specific assemblies.
* In a file (-f *paramater see 2.1 and 2.2*). With this file, it is possible to add informations to improve assemblies of this material. This informations should be a reference to use for final assembly evaluation, included or excluded files for file selection or to ask for a specific assembly (ex: if user want only hybrid assembly).

In the first case, for each material:  
1. Selection of Illumina files. (It is not possible to exclude or include file)
2. Selection of Nanopore file. (It is not possible to exclude or include file)
3. Assemblies by AMALGAM.
4. If short reads and hybrid assemblies are performed, there is a comparison of resulted assemblies.
5. Move on the next material.

In the second case, there are additional steps related to material file:
1. Extract information about the material (Reference file, assembly(ies) to perform, file to exclude or include)
1. Selection of Illumina files. (See 1.1.1.)
2. Selection of Nanopore file. (See 1.1.2.)
3. Assemblies by AMALGAM.
4. If short reads and hybrid assemblies are mades, there is a comparison of resulted assemblies.
5. Move on the next material.


## 2. AMALGAM script inputs
### 2.1 General parameters

-h | --help     
&nbsp;&nbsp;&nbsp;&nbsp;Display help message  
-p | --project  
&nbsp;&nbsp;&nbsp;&nbsp;Name of the project (3 letters ex: BPK) **REQUIRED**  
-m | --material  
&nbsp;&nbsp;&nbsp;&nbsp;Material(s) name(s) (1 to 4 letters). **REQUIRED** if no --material-file  
-f | --material-file  
&nbsp;&nbsp;&nbsp;&nbsp;File with material(s) name in column. **REQUIRED** if no --material  
-o | --output_path  
&nbsp;&nbsp;&nbsp;&nbsp;Output directory. **REQUIRED**  
-c | --cpu  
&nbsp;&nbsp;&nbsp;&nbsp;Number of CPU to use for each assembly. **OPTIONAL** *(By default : 6)*  
--partition  
&nbsp;&nbsp;&nbsp;&nbsp;Name of the partition to execute assembly(ies) **OPTIONAL** *(By default : normal)*  
--demo  
&nbsp;&nbsp;&nbsp;&nbsp;Display commands lines for amalgam executions. Does not execute assemblies and does not write scripts.

#### EXEMPLE OF COMMAND LINE :   
*Minimal command line with only required parameters*

##### With a list of materials:
amalgam_wrapper -p *< project >* -o *< output_directory >* -m *< list_of_material(s) >*
##### With a file whitch contains a list of material:
amalgam_wrapper -p *< project >* -o *< output_direcyory >* -f *< file_of_material(s) >*

### 2.2 File of material(s) :

This file should be specify in *-f* parameter.  
For one material, informations should be on one ligne and must be separated with tabulation.

Each condition is specified by a keyword:

**IN_IL** : List of Illumina files to assemble. (two files per material) *(separator ",")*  
**EX_IL**  -> List of Illumina files not to be assemble. *(separator ",")*  
**IN_NP** -> List of Nanopore files to assemble. (maximum one file per material) *(separator ",")*  
**EX_NP** -> List of Nanopore files not to be assemble. *(separator ",")*  
(For each previous lists, we must write only file name with no path)  
**REF** -> Reference to use in comparison step (one fasta file)  
**ASS** -> Type of assembly(ies) to do (short and/or hybrid) *(separator ",")*  

It is only possible to exclude **or** inclure files.

##### Format:  
 *< Material >*&nbsp;&nbsp;&nbsp;&nbsp;IN_IL:*< List of file >*&nbsp;&nbsp;&nbsp;&nbsp;REF:*< Fasta file >*

##### Exemple of file :

A&nbsp;&nbsp;&nbsp;&nbsp;REF:referenceA.fasta&nbsp;&nbsp;&nbsp;&nbsp;IN_IL:forward.fastq,reverse.fastq&nbsp;&nbsp;&nbsp;&nbsp;EX_NP:file1.fastq,file2.fastq&nbsp;&nbsp;&nbsp;&nbsp;ASS:Short,Hybrid  
B&nbsp;&nbsp;&nbsp;&nbsp;IL_NP:file1.fastq&nbsp;&nbsp;&nbsp;&nbsp;ASS:Short  
C  
D&nbsp;&nbsp;&nbsp;&nbsp;REF:referenceD.fasta&nbsp;&nbsp;&nbsp;&nbsp;EX_NP:file1.fastq 	

## 3. Outputs

For each execution of AMALGAM wrapper a repository is created (if it does not already exist). It is named AMALGAM_*Project*.

This folder contains AMALGAM wrapper repositories and folders comes from AMALGAM tool.

### 3.1 Output wrapper directories
As from AMALGAM tool, this script made repositories for log files and necessaries scripts.

* *Project*\_logger contains :
  * File with log written by wrapper script. (Contain all information for gerenal execution and for all materials : files, command lines, message INFO and ERROR ...). (See 4.)
  * File with key logs written by wrapper script (See 4.). This file is a summary of INFO an ERROR messages.
  * Standard/Error output files from clusters jobs.
* *Project*\_scripts contains all scripts which are launch on slurm clusters.

### 3.2 AMALGAM directories

In project directory "AMALGAM_*Project*" there is output AMALGAM assemblies. One repository is created by material (with material name) and contains all assemblies of this data set. Each material repository contains at most 3 repositories :
* S.< *Project* >\_< *Material* > *(ex : S.BPK_BA)*  
 Contains short reads assemblies. It corresponds to AMALGAM output *(see Documentation for AMALGAM users)*.
* H.< *Project* >\_< *Material* > *(ex : H.BPK_BA)*  
Contains hybrid assembly.  It corresponds to AMALGAM output *(see Documentation for AMALGAM users)*.
* < *Project* >\_< *Material* >.comparison  *(ex : BPK_BA.comparison)*  
Is a  comparison of all mades assemblies for this material. This is a result of a QUAST/ICARUS analysis between short reads assemblies and hybrid assembly.

These last two repositories are there only when there is a long reads file (Nanopore).

## 4. Description of return messages

All this messages are reported in AMALGAM_*Project*.log file in logger repository (*project*\_logger) and are summarised in AMALGAM_*Project*.err file.

Depending on the step in error, sequence of steps is different. There is two types of retrun :
* INFO -> Reports an observation or a problem but did not prevent to start step. It is important to read it in order to correct this point.
* ERROR -> A problem is encountered and lead to the non-launch of a step.

For all material, no assemblies start if:
* Required parameters are not specified or are incorrect.
* Material file is unkown or empty. (If -f parameter is used)

For one material, there is ERROR report if:
* Number of file is unexpected.
* Material is ask several times.
* There is file to include and file to exclude.

For one material, there is INFO report if :
* Reference file is not found.
* There is a problem in Nanopore file selection (No file or more than one file found) -> Hybrid assembly is not performed.
* Information in material file is unknown but as no impact on assembly.

## 5. About scripts executions

### 5.1. Job names 

S.*Project*\_*Material* -> AMALGAM for short reads assemblies  
H.*Project*\_*Material* -> AMALGAM for hybrid assembly  
E.*Project*\_*Material* -> Assemblies comparison (job id extraction)  
C0.*Project*\_*Material* -> Assemblies comparison (write script part)  
C1.*Project*\_*Material* -> Assemblies comparison (start assemblies comparison job)  
L.*Project* -> Write last message in log file  


## Script diagram


### With list of material (parameter -m)
----------------------------------------
![Step with list of material](Diapositive3.png)

### With file of material (parameter -f)
----------------------------------------
![Step with file of material](Diapositive2.png)
