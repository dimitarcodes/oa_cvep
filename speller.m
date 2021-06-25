%% CVEP SPELLER
% runs the cvep speller simulation in 3 configurations:
%   1) original beta stopping cvep speller
%   2) modified predicted gaze prior + beta stopping cvep speller
%   3) modified idealized gaze prior + beta stopping cvep speller
%% RESET + LOAD LIBS

restoredefaultpath;
clear variables;
close all;
clc;

% Root to project content
root = fullfile(filesep,'Thesis', 'Experiment');

% Add fieldtrip
ft_root = fullfile(root, 'fieldtrip');
addpath(ft_root);

% Add utilities
util_path = genpath(fullfile(root, 'utilities'));
addpath(util_path);

% Add eye toolbox
oa_root = fullfile(root, 'оа_toolbox');
addpath(oa_root)

% Add cvep toolbox
cvep_root = fullfile(root, 'cvep_toolbox');
addpath(cvep_root)

%--------------------------------------------------------------------------
%% Constants
%--------------------------------------------------------------------------

%subject = 'sub-01';
%suffix = 'gdf';

fs = 360; % Data sample frequency
fr = 120;

n_response_samples = 0.2 * fs; % Length of transient response

maxtime = 4.2;
L = 0.2;

n_classes = 36;
n_simulations = 1;

segmenttime = 0.1;
n_segments = floor(maxtime/segmenttime);

intertrialtime = 2.0;
n_segment_samples = floor(segmenttime * fs);

% cVEP minimum time before making decision + target margin accuracy
mintime = 0.5;
accuracy = 0.99;

% saccade prior boost
boost = 0.01; 

% configuration of saccade analysis
anacfg = [];
anacfg.lowtresh = 1300;
anacfg.hightresh = 3200;

% create subject names
subecterinos = [];
for subs=1:9
   subecterinos = [subecterinos; strcat('sub-0', num2str(subs))]; 
end
subecterinos = [subecterinos; 'sub-10'];
subecterinos = [subecterinos; 'sub-11'];
subecterinos = [subecterinos; 'sub-12'];


%% SPELLER
for subs = 1:12
    subject = subecterinos(subs,:);
    bandpass = [2 48];
    % SPELLER AND SACCADE CLASSIFIER TRAINING DATASETS - dont loop this
    % read speller training data
    train_data = [];
    [train_data.X, train_data.y, train_data.V]  = read_data(root, subject, 'train', ft_root, fs, bandpass);
    % SPELLER AND SACCADE TEST DATASETS - loop this
    % read speller testing data

    for runner = 1:3
        run = strcat('test_sync_',num2str(runner));
        
        test_data = [];
        [test_data.X, test_data.y, test_data.U]     = read_data(root, subject, run, ft_root, fs, bandpass);
        
        % cVEP train phase
        cfg = [];
        cfg.verbosity       = 0;
        cfg.fs              = fs;
        cfg.maxtime         = maxtime;
        cfg.intertrialtime  = intertrialtime;
        cfg.method          = 'fwd';
        cfg.L               = L;
        cfg.stopping        = 'beta';
        cfg.accuracy        = accuracy;

        V_train = jt_upsample(train_data.V, fs / fr);
        U_valid = jt_upsample(test_data.U, fs / fr);
        
        % Train classifier
        cl_beta = jt_tmc_train(struct('X', train_data.X, 'y', train_data.y, 'V', V_train, 'U', U_valid), cfg);
        
        % Copy classifier to one with saccade setting
        cl_sacc = cl_beta;
        cl_sacc_ideal = cl_beta;
        %cl_sacc.cfg.stopping = 'saccade';

        % Select validation data (both spellers need this)
        data = test_data.X;
        true_labels = test_data.y;
        n_trials = numel(true_labels);
        
        %%
        %--------------------------------------------------------------------------
        % RUN ORIGINAL SPELLER
        %--------------------------------------------------------------------------

        prediction_beta         = nan(1, n_trials);
        prediction_time_beta    = nan(1, n_trials);

        for i_trial = 1:n_trials

            X = data(:, :, i_trial);

            % Deliver data in segments, simulating real world and allowing early
            % stop
            for i_segment = 1:n_segments

                [yh_beta, result_beta, cl_beta] = jt_tmc_apply(cl_beta, X(:, 1:round(i_segment * segmenttime * cfg.fs)));

                % if beta classifier has reached confidence threshold
                if ~isnan(yh_beta)
                        % record the solution
                        prediction_beta(i_trial) = yh_beta;
                        % record the time it took to reach confidence
                        prediction_time_beta(i_trial) = result_beta.t; 
                        break;
                end  
            end
        end

        %decodingtime = sum(prediction_time_beta + intertrialtime);
        
        %%
        %--------------------------------------------------------------------------
        % RUN NEW AND IMPROVED(?) SPELLER - FAKE REAL TIME
        %--------------------------------------------------------------------------
        
        [sax,~] = oa_analysis_precomputed(root, subject, run, anacfg);
        prediction_sacc         = nan(1, n_trials);
        prediction_time_sacc    = nan(1, n_trials);


        for i_trial = 1:n_trials

            prior = oa_prior(sax(i_trial), boost);
            X = data(:, :, i_trial);

            for i_segment = 1:n_segments

                [yh_sacc, result_sacc, cl_sacc] = jt_tmc_apply_ds(cl_sacc, prior, X(:, 1:round(i_segment * segmenttime * cfg.fs)));

                % if saccade classifier has reached confidence threshold
                if ~isnan(yh_sacc)
                        % record the solution
                        prediction_sacc(i_trial) = yh_sacc;
                        % record the time it took to reach confidence
                        prediction_time_sacc(i_trial) = result_sacc.t; 
                        break;
                end  


            end
        end
        
        %%
        %--------------------------------------------------------------------------
        % RUN NEW IDEALIZED(!) SPELLER - FAKE REAL TIME
        %--------------------------------------------------------------------------
        
        sax_ideal = true_labels;
        sax_ideal(sax_ideal < 17 ) = 1;
        sax_ideal(sax_ideal > 16 ) = -1;

        prediction_sacc_ideal         = nan(1, n_trials);
        prediction_time_sacc_ideal    = nan(1, n_trials);
        

        for i_trial = 1:n_trials

            prior = oa_prior(sax_ideal(i_trial), boost);
            X = data(:, :, i_trial);

            for i_segment = 1:n_segments

                [yh_sacc_ideal, result_sacc_ideal, cl_sacc_ideal] = jt_tmc_apply_ds(cl_sacc_ideal, prior, X(:, 1:round(i_segment * segmenttime * cfg.fs)));

                % if saccade classifier has reached confidence threshold
                if ~isnan(yh_sacc_ideal)
                        % record the solution
                        prediction_sacc_ideal(i_trial) = yh_sacc_ideal;
                        % record the time it took to reach confidence
                        prediction_time_sacc_ideal(i_trial) = result_sacc_ideal.t; 
                        break;
                end  


            end
        end
        
        %%

        results = [];
        results.true_labels = true_labels;
        results.prediction_beta = prediction_beta;
        results.prediction_sacc = prediction_sacc;
        results.prediction_sacc_ideal = prediction_sacc_ideal;
        results.prediction_time_beta = prediction_time_beta;
        results.prediction_time_sacc = prediction_time_sacc;
        results.prediction_time_sacc_ideal = prediction_time_sacc_ideal;
        results.boost = boost;
        results.sacctresh = [anacfg.lowtresh anacfg.hightresh];
        
        [~,~,~] = mkdir(fullfile(root,'precomputed', 'experiment'));
        save(fullfile(root, 'precomputed', 'experiment', strcat(subject, '_', run,'_results.mat')), 'results');
    end
end


          