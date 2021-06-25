%% OCULAR ARTEFACTS BULK FEATURE EXTRACTION
% this script's purpose is to extract features from every subject's data
% for faster analysis
%% RESET + LOAD LIBS

restoredefaultpath;
clear variables;
close all;
clc;

% Root to project content
root = fullfile(filesep, 'Thesis', 'Experiment');

% Add fieldtrip
ft_root = fullfile(root, 'fieldtrip');
addpath(ft_root);

% Add utilities
util_path = genpath(fullfile(root, 'utilities'));
addpath(util_path);

%% create list of subjects
subecterinos = [];
for subs=1:9
   subecterinos = [subecterinos; strcat('sub-0', num2str(subs))]; 
end
subecterinos = [subecterinos; 'sub-10'];
subecterinos = [subecterinos; 'sub-11'];
subecterinos = [subecterinos; 'sub-12'];

%% go over all subjects and extract all features
for subs = 1:12
    subject = subecterinos(subs,:);
    for runner = 1:3
        run = strcat('test_sync_',num2str(runner));
        data = oa_read_data(root, subject, run, ft_root);
        [source, features] = oa_feature_extraction(data);
        savepath = fullfile(root, 'precomputed', strcat(subject, '_', run, '_precomupted_nodemeannodetrend.mat'));
        in = load(fullfile(root, 'sourcedata', subject, run, strcat(subject, '_', run,'.mat')));
        labels = in.labels(:);
        save(savepath, 'source', 'features', 'labels');
    end
end