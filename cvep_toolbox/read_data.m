function [data, labels, codes] = read_data(root, subject, run, ft_root, resamplefs, bpfreq)
% [data, labels, codes] = read_data(root, subject, run, ft_root, resamplefs, bpfreq)
% Reads the data from [1], preprocesses it, and slices into single-trials.
% It also extracts the presented codes' labels and bit-sequences.
%
% Notes:
%   - Training runs ('train' and 'practice') contain the training codes,
%   which are modulated Gold codes with feedback tap positions at [6 5 2 1]
%   and [6 1].
%   - Testing runs ('test_sync', 'test_stop', and 'free') contain the 
%   testing codes, which are modulated Gold codes with feedback tap 
%   positions at [6 5 3 2] and [6 5].
%   - Training runs always used subset and layout 1:36.
%   - Testing runs' subset and layout were optimized for each individual
%   subject, see [1].
%   - The stopping runs ('test_stop') contain testing trials with the
%   classification algorithm applied using dynamic stopping. Hence, these
%   trials are of varying lengths. 
%
% [1] Thielen, J., van den Broek, P., Farquhar, J., & Desain, P. (2015). 
% Broad-Band visually evoked potentials: re(con)volution in 
% brain-computer interfacing. PloS one, 10(7), e0133797.
%
% INPUT
%   root       = [str] path to the data
%   subject    = [str] subject to read of form 'sub-01'
%   run        = [str] run to read (practice_1, practice_2, train, 
%                      test_sync_1, test_sync_2, test_sync_3, test_stop_1, 
%                      test_stop_2, test_stop_3, free_stop)
%   ft_root    = [str] path to the fieldtrip toolbox
%   resamplefs = [int] target downsample frequency (default=360)
%   bpfreq     = [1 2] band-pass with [highpass lowpass] (default=[2 48])
%
% OUTPUT
%   data   = [c m k] EEG data of c channels, m samples, and k trials
%   labels = [k 1]   labels (i.e., code indices) of k trials
%   codes  = [s n]   n presented (at 120 hz) bit-sequences of s samples
%
% Author: Jordy Thielen
% Date: 02-05-2018

% Defaults
if nargin < 5 || isempty(resamplefs); resamplefs = 360; end
if nargin < 6 || isempty(bpfreq); bpfreq = [2 48]; end

% Add fieldtrip
if isempty(which('ft_definetrial'))
    addpath(ft_root);
    ft_defaults;
end

% Read and slice data
cfg = [];
cfg.feedback = 'none';
cfg.dataset  = fullfile(root, 'sourcedata', subject, run, sprintf('%s_%s.gdf', subject, run));
cfg.trialfun = @ft_trialfun_general;
cfg.trialdef.eventtype = 'STATUS';
cfg.trialdef.eventvalue = 1:2; % event value: 1 for training trials' onset, 2 for testing trials onset
cfg.trialdef.prestim = 0; % before stimulus onset
cfg.trialdef.poststim = 4.2; % after stimulus onset
cfg = ft_definetrial(cfg);
cfg.channel = 2:65; % channel 1 is STATUS channel, 64 10/20 cap (biosemi64.lay)
data = ft_preprocessing(cfg);

% Spectral filter
cfg = [];
cfg.feedback = 'no';
cfg.bpfilter = 'yes';
cfg.bpfreq = bpfreq;
data = ft_preprocessing(cfg, data);

% Downsample
cfg = [];
cfg.feedback = 'no';
cfg.resamplefs = resamplefs;
cfg.detrend = 'yes';
cfg.demean = 'yes';
data = ft_resampledata(cfg, data);

% Extract data matrix
data = reshape([data.trial{:}], numel(data.label), [], numel(data.trial));

% Read labels
in = load(fullfile(root, 'sourcedata', subject, run, sprintf('%s_%s.mat', subject, run)));
labels = in.labels(:);

% Read codes
codes = in.codes(:, in.subset(in.layout));
