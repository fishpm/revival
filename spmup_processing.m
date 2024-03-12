%% Description

% Script for processing REVIVAL healthy control data using spmup

%% add paths

% spmup (https://github.com/CPernet/spmup) provides a framework for processing BOLD fMRI data using SPM tools
addpath(genpath('/users/patrick/matlab/spmup/'))

% use spm12
addpath(genpath('/usr/local/nru/spm12'))

%% copy and unpack HC data

BIDS_dir                = '~/bids-hc'; 								% folder containing raw bids-curated data
options 				= spmup_getoptions(BIDS_dir); 				% default spmup options
options.outdir          = '~/bids-derivatives/BIDS_derivatives'; 	% derivatives output folder
options.Ncores          = 4; 										% parallel processing
options.anat            = {'rec-ND_run-1_T1w', 'rec-ND_run-1_T2w'}; % use anat with distortions matching func
options.task 			= {'rest'}; 								% rest bold data
options.despike         = 'off'; 									% no despiking
options.norm_res		= 3; 										% resample to 3mm isotropic
options.skernel         = 3; 										% smooth by 3x voxel size (9mm)
options.GLM             = 'off';									% no glm modeling by spmup

% load previously generated outputs (if present)
local_code = '~/bids-derivatives/Code';
if exist(fullfile(local_code,'BIDS-hc.mat'),'file') && ...
        exist(fullfile(local_code,'subjects-hc.mat'),'file')
    load(fullfile(local_code,'BIDS-hc.mat'))
    load(fullfile(local_code,'subjects-hc.mat'))
else
    [BIDS,subjects]         = spmup_BIDS_unpack(BIDS_dir,options); % unpacks
end

% ----------- save for next time ----------
save(fullfile(local_code,'options-hc.mat'),'options');
save(fullfile(local_code,'BIDS-hc.mat'),'BIDS');
save(fullfile(local_code,'subjects-hc.mat'),'subjects');

%% copy and unpack patient data

BIDS_dir                = '~/bids'; 								% folder containing raw bids-curated data
options 				= spmup_getoptions(BIDS_dir);				% default spmup options
options.outdir          = '~/bids-derivatives/BIDS_derivatives';	% derivatives output folders
options.Ncores          = 4; 										% parallel processing
options.anat            = {'rec-norm_T1w', 'rec-norm_T2w'};			% use anat with distortions matching func
options.ses             = 'ses-01'; 								% pull from first session (baseline)
options.task 			= {'rest'}; 								% rest bold data
options.despike         = 'off'; 									% no despiking
options.norm_res		= 3; 										% resample to 3mm isotropic
options.skernel         = 3; 										% smooth by 3x voxel size (9mm)
options.GLM             = 'off';									% no glm modeling by spmup

% load previously generated outputs (if present)
local_code = '~/bids-derivatives/Code';
if exist(fullfile(local_code,'BIDS-pt.mat'),'file') && ...
        exist(fullfile(local_code,'subjects-pt.mat'),'file')
    load(fullfile(local_code,'BIDS-pt.mat'))
    load(fullfile(local_code,'subjects-pt.mat'))
else
    [BIDS,subjects]         = spmup_BIDS_unpack(BIDS_dir,options); % unpacks
end

% ----------- save for next time ----------
save(fullfile(local_code,'options-pt.mat'),'options');
save(fullfile(local_code,'BIDS-pt.mat'),'BIDS');
save(fullfile(local_code,'subjects-pt.mat'),'subjects');

%% Preprocess data with spmup

% load BIDS and subjects files
local_code = '~/bids-derivatives/Code';

% suffix for file names for two groups
groups = {'-hc', '-pt'};

for group = 1:numel(groups)
    
    preproc_subjects = {};
    opt = {};
    
    load(fullfile(local_code,['options' groups{group} '.mat']),'options');
    load(fullfile(local_code,['BIDS' groups{group} '.mat']),'BIDS');
    load(fullfile(local_code,['subjects' groups{group} '.mat']),'subjects');
    
    for sub = 1:size(subjects,2)
        
        % skip if sub is without func data
        if ~isfield(subjects{sub}, 'func')
            continue
        end
        
        for session = 1:size(subjects{sub}.func,1)
            fprintf(['Subject: ' num2str(sub) '/' num2str(size(subjects,2)) '; session: ' num2str(session) '/' num2str(size(subjects{sub}.func,1)) '.\n' ])
			
            % try to run spmup
            try
                % define input data
                subject_sess.anat = ...
                    subjects{sub}.anat(session,cellfun(@(x) ~isempty(x), subjects{sub}.anat(session,:)))';
                if ~iscell(subject_sess.anat)
                    subject_sess.anat           = {subject_sess.anat};
                end
                subject_sess.func = subjects{sub}.func(session,:)';
                subject_sess.func_metadata = subjects{sub}.func_metadata(session,:)';
                subject_sess.fieldmap = subjects{sub}.fieldmap(session);
                
                % ensure that relevant .nii files are unzipped
                currwd = pwd;
                anatparts = strsplit(subjects{sub}.anat{1}, '/');
                subidx = find(~cellfun(@isempty, regexp(anatparts, '^(sub-)', 'once'), 'UniformOutput', true),1);
                cd(fullfile('/',anatparts{1:subidx}))
                unix('for i in `find | grep -E "\.nii.gz$"`; do gunzip "$i" ; done');
                cd(currwd)
                
                % run spmup preprocessing
                [preproc_subjects{sub,session},opt{sub,session}] = ...
                    spmup_BIDS_preprocess(subject_sess, options);
                
                % save noise parameters into single file
                davg = spmup_comp_dist2surf(preproc_subjects{sub,session}.anat{1},...
                    preproc_subjects{sub,session}.tissues{1},...
                    preproc_subjects{sub,session}.tissues{2});
                
                for f=1:size(preproc_subjects{sub,session}.func,1)
                    out = spmup_first_level_qa(preproc_subjects{sub,session}.func{f}, ...
                        'Radius',davg, ...
                        'Movie','off','Voltera','on',...
                        'Framewise displacement','on','Globals','on');
                    preproc_subjects{sub,session}.func_qa{f}.FD = out.FD;
                    preproc_subjects{sub,session}.func_qa{f}.globals = out.glo;
                    preproc_subjects{sub,session}.design{f} = out.design;
                end
            catch
                preproc_subjects{sub,session} = 'something went wrong';
                opt{sub,session} = options;
            end
        end
        % zip files after processing
        anatparts = strsplit(subjects{sub}.anat{1}, '/');
        subidx = find(~cellfun(@isempty, regexp(anatparts, '^(sub-)', 'once'), 'UniformOutput', true),1);
        currwd = pwd;
        cd(fullfile('/', anatparts{1:subidx}))
        unix('for i in `find | grep -E "\.nii$"`; do gzip "$i" ; done');
        cd(currwd)
    end
    % save information
    save(fullfile(BIDS.dir, ['preproc_subjects' groups{group} '.mat']),'preproc_subjects');
    save(fullfile(BIDS.dir, ['opt' groups{group} '.mat']),'opt');
end

fprintf('spmup processing completed successfully!!\n')

%% check outputs for, e.g., missing data

subDir = dir(fullfile(BIDS.dir, 'sub*'));
for i = 1:numel(subDir)
    
    fDir = dir(fullfile(subDir(i).folder, subDir(i).name, 'func', 'run-1', '*nii.gz'));
    if numel(fDir)==0
        fDir = dir(fullfile(subDir(i).folder, subDir(i).name, 'ses-01', 'func', 'run-1', '*nii.gz'));
        if numel(fDir)==0
            disp(['No func data: ' subDir(i).name])
            continue
        end
    end
    
    matches = cellfun(@isempty, regexp({fDir.name}, '(desc-preprocessed_bold.nii.gz)$', 'once'), 'UniformOutput', true);
    if all(matches)
        disp(['No processed data: ' subDir(i).name])
        continue
    else
        idx = find(~matches);
        fDir = fDir(idx);
    end
    
    v = MRIread(fullfile(fDir.folder, fDir.name));
    if v.nframes ~= 300
        disp([num2str(v.nframes) ' volumes: ' subDir(i).name])
        continue
    end
    
    [~,fn,~] = fileparts(fDir.name);
    [~,fn,~] = fileparts(fn);
    jsonEncode = jsondecode(fileread(fullfile(fDir.folder, [fn '.json'])));
    if ~strcmp(jsonEncode.realign.type, 'realign and unwarp (with field map correction)')
        disp([jsonEncode.realign.type ': ' subDir(i).name])
    end
    if ~strcmp(num2str(jsonEncode.normalise.resolution'), '3  3  3')
        disp(['norm: ' num2str(jsonEncode.normalise.resolution') ': ' subDir(i).name])
    end
    if ~strcmp(num2str(jsonEncode.smoothingkernel'), '9  9  9')
        disp(['smooth: ' num2str(jsonEncode.smoothingkernel') ': ' subDir(i).name])
    end    
end


