# revival
Code related to processing REVIVAL project data

## File summary
spmup_processing.m: process fmri data using spmup (https://github.com/CPernet/spmup), which applies spm12 (https://www.fil.ion.ucl.ac.uk/spm/software/spm12/)<br>
art.m: apply ART (https://www.nitrc.org/projects/artifact_detect/) to detect outlier volumes for censoring<br>
conn_extraction.m: apply connReader, internal code for extracting functional connectivity estimates (within- and between-network functional connectivity and global connectivity)
