%% RESULTS ANALYSIS
% prints results from cvep runs with and without ocular artefacts prior
%% RESET + LOAD LIBS

restoredefaultpath;
clear variables;
close all;
clc;

%% initialize constants
root = fullfile(filesep, 'Thesis', 'Experiment_new');
subs = 12;
bps = 3;
tpb = 36;
ntrials = tpb*subs*bps;
%% initialize trackers
% labels
label    = nan(1,ntrials);
beta    = nan(1,ntrials);
sacc    = nan(1,ntrials);
ideal   = nan(1,ntrials);

% time
tbeta   = nan(1,ntrials);
tsacc   = nan(1,ntrials);
tideal  = nan(1,ntrials);

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
        
        curr_indices = (subs-1)*bps*tpb + (runner-1)*tpb + 1 : (subs-1)*bps*tpb + runner*tpb;
        fprintf('start idx: %d end idx: %d\n', curr_indices(1), curr_indices(end));
        
        %labels
        label(curr_indices)    = in.results.true_labels;
        beta(curr_indices)    = in.results.prediction_beta;
        sacc(curr_indices)    = in.results.prediction_sacc;
        ideal(curr_indices)   = in.results.prediction_sacc_ideal;

        % time
        tbeta(curr_indices)   = in.results.prediction_time_beta;
        tsacc(curr_indices)   = in.results.prediction_time_sacc;
        tideal(curr_indices)  = in.results.prediction_time_sacc_ideal;
    end
end

%% corrected saccades 

corrected_beta_ideal = sum(beta ~= label & ideal == label);
fprintf('corrected saccades beta-ideal: %d\n', corrected_beta_ideal);

corrected_beta_sacc = sum(beta ~= label & sacc == label);
fprintf('corrected saccades beta-sacc: %d\n', corrected_beta_sacc);

%% broken saccades

broken_beta_ideal = sum(beta == label & ideal ~=label);
fprintf('broken saccades beta-ideal: %d\n', broken_beta_ideal);

broken_beta_sacc = sum(beta == label & sacc ~=label);
fprintf('broken saccades beta-sacc: %d\n', broken_beta_sacc);

%% accuracy comparison
fprintf('beta classifier accuracy: %f\n', sum(beta==label)/ntrials );

fprintf('ideal saccade classifier accuracy: %f\n', sum(ideal==label)/ntrials );

fprintf('saccade classifier accuracy: %f\n', sum(sacc==label)/ntrials );
%% time comparison
fprintf('beta classifier average classification time: %f\n', mean(tbeta));

fprintf('ideal saccade classifier average classification time: %f\n', mean(tideal));
fprintf('saccade classifier average classification time: %f\n', mean(tsacc));
%%  runnning time
fprintf('beta classifier runnning time: %f\n', sum(tbeta)+2*ntrials);
fprintf('ideal saccade classifier runnning time: %f\n', sum(tideal)+2*ntrials);
fprintf('saccade classifier runnning time: %f\n', sum(tsacc)+2*ntrials);

%%  lost time
fprintf('ideal saccade classifier lost time: %f\n', sum(tideal(beta == label & ideal ~=label)) +broken_beta_ideal*2  );
fprintf('saccade classifier lost time: %f\n', sum(tsacc(beta == label & sacc ~=label)) +broken_beta_sacc*2 );

%% gained time
fprintf('ideal saccade classifier gained time: %f\n', sum(tbeta(beta ~= label & ideal ==label)) +broken_beta_ideal*2  );
fprintf('saccade classifier gained time: %f\n', sum(tbeta(beta ~= label & sacc ==label)) +broken_beta_sacc*2 );

%%  running time
fprintf('beta classifier runnning time: %f\n', sum(tbeta)+2*ntrials);
fprintf('ideal saccade classifier runnning time: %f\n', sum(tideal)+2*ntrials);
fprintf('saccade classifier runnning time: %f\n', sum(tsacc)+2*ntrials);


%% both correct times
beta_ideal_correct = (beta == label & ideal == label);
beta_ideal_correct_gain = sum(tbeta(beta_ideal_correct)) - sum(tideal(beta_ideal_correct));
fprintf('beta-ideal correct n: %d gained time: %f\n', sum(beta_ideal_correct), beta_ideal_correct_gain);

beta_sacc_correct = (beta == label & sacc == label);
beta_sacc_correct_gain = sum(tbeta(beta_sacc_correct)) - sum(tideal(beta_sacc_correct));
fprintf('beta-sacc correct n: %d gained time: %f\n', sum(beta_sacc_correct), beta_sacc_correct_gain);

%% both wrong
beta_ideal_wrong = beta ~= label & ideal ~= label;
beta_ideal_wrong_gain = sum(tbeta(beta_ideal_wrong)) - sum(tideal(beta_ideal_wrong));
fprintf('beta-ideal wrong n: %d gained time: %f\n', sum(beta_ideal_wrong), beta_ideal_wrong_gain);

beta_sacc_wrong = beta ~= label & sacc ~= label;
beta_sacc_wrong_gain = sum(tbeta(beta_sacc_wrong)) - sum(tideal(beta_sacc_wrong));
fprintf('beta-sacc wrong n: %d gained time: %f\n', sum(beta_sacc_wrong), beta_sacc_wrong_gain);

