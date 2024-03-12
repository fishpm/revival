# revival
Code related to processing REVIVAL project data

## File summary
spmup_processing.m: processing of fmri data using spmup (https://github.com/CPernet/spmup), a toolbox that applies spm12-based processing steps
art.m: apply ART (https://www.nitrc.org/projects/artifact_detect/) to detect outlier volumes for censoring
conn_extraction.m: apply connReader, internal code for extracting functional connectivity estimates (within- and between-network functional connectivity and global connectivity)
