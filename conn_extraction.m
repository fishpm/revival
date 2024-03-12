%% Description

% Extract within- and between-network connectivity as well as global connectivity from a CONN structure for a specific atlas.

%% addpath
addpath('/users/patrick/gitlab/connReader')

%% conn structure

infile = '~/bids-derivatives/conn2/conn_project01.mat';

atlas = 'networks';

options = connExtract(infile, atlas);

% data copied and pasted to .csv file
a = options.summary.mean{1};
a.Properties.VariableNames' % column names

% get all network-relevant region-to-region connections
cm          = load(options.cmFile{1}); 			% load file containing region-to-region connectivity values for all participants
idxnames    = find(contains(cm.names, atlas));  % network-relevant region names on "x-axis"
idxnames2   = find(contains(cm.names2, atlas)); % network-relevant region names on "y-axis"
[m,n]       = ndgrid(idxnames, idxnames2); 		% combination of all network-relevant indices
cellidx = [m(:) n(:)]; 							% column 1 is "x-axis" position, column 2 is "y-axis"

% global connectivity (defined as mean of all region-to-region connections)
gc = zeros(size(cm.Z,3),1);

% for each dataset...
for sub = 1:size(cm.Z,3)
    vals = zeros(size(cellidx,1),1); % number of region-to-region connections
    % for each region-to-region connection...
    for idx = 1:size(cellidx,1)
        vals(idx) = cm.Z(cellidx(idx,1), cellidx(idx,2), sub); % extract region-to-region connection value
    end
    gc(sub,1) = mean(vals, 'omitnan'); % cellidx includes self-region pairs, which have NaN value
end