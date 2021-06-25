%% RESULTS ANALYSIS READY FOR LATEX
% pprints results from cvep runs with and without ocular artefacts prior
% in a way that's ready to be pasted in a latex tabular environment
%% RESET + LOAD LIBS

restoredefaultpath;
clear variables;
close all;
clc;

root = fullfile(filesep, 'Thesis', 'Experiment');
disp(root);
% Add utilities
util_path = genpath(fullfile(root, 'utilities'));
addpath(util_path);
%% initialize constants
subs = 12;
bps = 3;
tpb = 36;
ntrials = tpb*subs*bps;
%% initialize trackers
% labels
label   = nan(subs,bps,tpb);
beta    = nan(subs,bps,tpb);
sacc    = nan(subs,bps,tpb);
ideal   = nan(subs,bps,tpb);

% time
tbeta   = nan(subs,bps,tpb);
tsacc   = nan(subs,bps,tpb);
tideal  = nan(subs,bps,tpb);

%% extract results
subecterinos = [];
for subs=1:9
   subecterinos = [subecterinos; strcat('sub-0', num2str(subs))]; 
end
subecterinos = [subecterinos; 'sub-10'];
subecterinos = [subecterinos; 'sub-11'];
subecterinos = [subecterinos; 'sub-12'];

for subs = 1:12
    subject = subecterinos(subs,:);
    for runner = 1:3
        run = strcat('test_sync_',num2str(runner));
        in = load(fullfile(root, 'precomputed', 'experiment', strcat(subject, '_', run,'_results.mat')));
        
        %labels
        label(subs, runner, :)    = in.results.true_labels;
        beta(subs, runner, :)    = in.results.prediction_beta;
        sacc(subs, runner, :)    = in.results.prediction_sacc;
        ideal(subs, runner, :)   = in.results.prediction_sacc_ideal;

        % time
        tbeta(subs, runner, :)   = in.results.prediction_time_beta;
        tsacc(subs, runner, :)   = in.results.prediction_time_sacc;
        tideal(subs, runner, :)  = in.results.prediction_time_sacc_ideal;
    end
end

%% print for latex tabular
accstring = "";
timestring = "";
cpmstring = "";
cpmsubstring = "";
for subs = 1:12
    subject = subecterinos(subs,:);
    
    %% accuracies
    
    ogacc = zeros(1,3);
    miacc = zeros(1,3);
    mpacc = zeros(1,3);
    
    ogtime = zeros(1,3);
    mitime = zeros(1,3);
    mptime = zeros(1,3);
    
    ogcpm = zeros(1,3);
    micpm = zeros(1,3);
    mpcpm = zeros(1,3);
    
    for runner = 1:3
        ogacc(runner) = sum(label(subs, runner, :) == beta(subs, runner, :))/tpb;
        miacc(runner) = sum(label(subs, runner, :) == ideal(subs, runner, :))/tpb;
        mpacc(runner) = sum(label(subs, runner, :) == sacc(subs, runner, :))/tpb;
        
        ogtime(runner) = sum(tbeta(subs, runner, :))/36;
        mitime(runner) = sum(tideal(subs, runner, :))/36;
        mptime(runner) = sum(tsacc(subs, runner, :))/36; 
        
        ogcpm(runner) = jt_itr(36, ogacc(runner), ogtime(runner), 'spm');
        micpm(runner) = jt_itr(36, miacc(runner), mitime(runner), 'spm');
        mpcpm(runner) = jt_itr(36, mpacc(runner), mptime(runner), 'spm');
    end
    
    ogmacc = mean(ogacc);
    mimacc = mean(miacc);
    mpmacc = mean(mpacc);
    
    [~, pmia] = ttest(ogacc, miacc);
    [~, pmpa] = ttest(ogacc, mpacc);
    
    accstring = strcat(accstring, sprintf('%d & %.4f\\%% & %.4f\\%% & %.3f & %.4f\\%% & %.3f \\\\ \\hline\n', ...
        subs, ogmacc*100, mimacc*100, pmia , mpmacc*100, pmpa));  
    
    %% times
    
    ogt = reshape(tbeta(subs, :, :), 1, []);
    mit = reshape(tideal(subs, :, :), 1, []);
    mpt = reshape(tsacc(subs, :, :), 1, []);  
    
    ogmtime = mean(ogt);
    mimtime = mean(mit);
    mpmtime = mean(mpt);
    
    [~, pmit] = ttest(ogt, mit);
    [~, pmpt] = ttest(ogt, mpt);
    
    timestring = strcat(timestring, sprintf('%d & %.4fs & %.4fs & %.4f & %.4fs & %.4f \\\\ \\hline\n', ...
        subs, ogmtime, mimtime, pmit, mpmtime, pmpt));
    
    %% per-block cpm + average over subject + p-val per subject ? 
    
    ogmcpm = mean(ogcpm);
    mimcpm = mean(micpm);
    mpmcpm = mean(mpcpm);
    
    [~, pmic] = ttest(ogcpm, micpm);
    [~, pmpc] = ttest(ogcpm, mpcpm);
    
    cpmstring = strcat(cpmstring, sprintf('%d & %.4f & %.4f & %.4f & %.4f & %.4f \\\\ \\hline\n', ...
        subs, ogmcpm , mimcpm, pmic, mpmcpm, pmpc));
    
    %% per-subject cpm
    
    ogscpm = jt_itr(108, ogmacc, ogmtime, 'spm');
    miscpm = jt_itr(108, mimacc, mimtime, 'spm');
    mpscpm = jt_itr(108, mpmacc, mpmtime, 'spm');
    
    cpmsubstring = strcat(cpmsubstring, sprintf('%d & %.4f ch/m & %.4f ch/m & %.4f ch/m \\\\ \\hline\n', ...
        subs, ogscpm , miscpm, mpscpm));
end