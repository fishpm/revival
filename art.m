%% Description

% applies artifact detection tools (https://www.nitrc.org/projects/artifact_detect/) to determine outlier volumes for censoring

%% Code

top = '~/bids-derivatives';
groups = {'-hc', '-pt'};

for i = 1:numel(groups)
    
    load(fullfile(top, 'Code', ['BIDS' groups{i} '.mat'])) % load BIDS structure
    
    for j = 1:numel(BIDS.subjects)
        fprintf(['Working on ' BIDS.subjects(j).name ': ' groups{i} ' ' num2str(j) '/' num2str(numel(BIDS.subjects)) '\n'])
		
		% skip if no func
        if isempty(BIDS.subjects(j).func)
            continue
        end
        
		% update ses if necessary
        if isempty(BIDS.subjects(j).func.ses)
            ses = '';
        else
            ses = ['ses-' BIDS.subjects(j).func.ses];
        end
		
		% get func files
        funcfile = fullfile(top, 'BIDS_derivatives',...
            BIDS.subjects(j).name, ...
            ses, ...
            'func', ...
            'run-1', ...
            '*space-IXI549_desc-preprocessed_bold.nii.gz');
		
		% get motion file
        rpfile = fullfile(top, 'BIDS_derivatives',...
            BIDS.subjects(j).name, ...
            ses, ...
            'func', ...
            'run-1', ...
            'rp*txt');
        funcDir = dir(funcfile);
        rpDir   = dir(rpfile);
        
		% unzip files
        [~,fn,ext] = fileparts(funcDir.name);
        unix(['gunzip ' fullfile(funcDir.folder, funcDir.name)]);
        
		% define art path
        artPath = fullfile(funcDir.folder, 'art');
        if ~exist(artPath, 'dir')
            mkdir(artPath)
        end
        
		% make art file
        fid=fopen([artPath '/art.cfg'],'wt');
        fprintf(fid,'sessions: %d\n',1);
        fprintf(fid,'global_mean: %d\n', 1); % global mean type (1: Standard 2: User-defined mask)
        fprintf(fid,'global_threshold: %d\n', 4); % threhsolds for outlier detection
        fprintf(fid,'motion_threshold: %d\n', 2); % threhsolds for outlier detection
        fprintf(fid,'motion_file_type: %d\n',0); % motion file type (0: SPM .txt file 1: FSL .par file 2:Siemens .txt file)
        fprintf(fid,'motion_fname_from_image_fname: %d\n',0); % 1/0: derive motion filename from data filename
        fprintf(fid,'use_diff_motion: %d\n',1);
        fprintf(fid,'use_diff_global: %d\n',1);
        fprintf(fid,'use_norms: %d\n',1);
        fprintf(fid,'image_dir: %s\n',funcDir.folder);
        fprintf(fid,'motion_dir: %s\n',funcDir.folder);
        fprintf(fid,'output_dir: %s\n',artPath);
        fprintf(fid,'end\n\n');
        fprintf(fid,'session 1 image ');
        fprintf(fid,fn);
        fprintf(fid,'\n\n');
        fprintf(fid,['session 1 motion ' rpDir.name '\n\n']);
        fprintf(fid,'end\n');
        fclose(fid);
        
		% run art and tidy outputs
        h=art('sess_file',fullfile(artPath, 'art.cfg'));
        export_fig(fullfile(artPath, 'art_overview.pdf'), '-pdf');
        close(h);
        unix(['mv ' funcDir.folder filesep 'art_* ' artPath]);
        
		% rezip files
        unix(['gzip ' fullfile(funcDir.folder, fn)]);
    end
    
end