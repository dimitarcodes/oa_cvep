function [data] = oa_read_data(root, subject, run, ft_root, cfg)
% function [data] = oa_read_data(root, subject, run, ft_root, cfg)
% reads and preprocesses gdf file from Thielen et al dataset and
% preprocesses it according to [1], [2], [3].
%
% [1] Belkacem, Abdelkader Nasreddine & Hirose, Hideaki & Yoshimura, 
% Natsue & SHIN, DUK & Koike, Yasuharu. (2014). Classification of Four Eye 
% Directions from EEG Signals for Eye-Movement-Based Communication Systems. 
% Journal of Medical and Biological Engineering. 34. 10.5405/jmbe.1596. 
%
% [2] Belkace, Abdelkader Nasreddine, et al. “Online Classification Algorithm 
% for Eye-Movement-Based Communication Systems Using Two Temporal EEG Sensors.” 
% Biomedical Signal Processing and Control, vol. 16, Feb. 2015, pp. 40–47. 
% www.sciencedirect.com, doi:10.1016/j.bspc.2014.10.005.
%
% [3] Belkacem, Abdelkader Nasreddine, et al. “Real-Time Control of a 
% Video Game Using Eye Movements and Two Temporal EEG Sensors.” Computational 
% Intelligence and Neuroscience, 15 Nov. 2015, 
% doi:https://doi.org/10.1155/2015/653639.

if nargin < 5
    cfg = [];
    cfg.feedback = 'none';
    cfg.refs  = 256;
    cfg.prestim = 2;
    cfg.poststim = 4.2;
    cfg.channels = {'F7', 'F8'}; % or [8,43] for F7 and F8
    cfg.bp = 'yes';
    cfg.bpfreq = [0.5 100]; 
    cfg.bs = 'yes';
    cfg.bsfreq = [48 52];
    cfg.demean = 'no';
    cfg.detrend = 'no';
end

% Add fieldtrip
if isempty(which('ft_definetrial'))
    addpath(ft_root);
    ft_defaults;
end

%% Read and slice data
filepath = fullfile(root, 'sourcedata', subject, run, strcat(subject,'_',run,'.gdf'));
% Read and slice data
cfg_read = [];
cfg_read.feedback               = cfg.feedback;
cfg_read.dataset                = filepath;
cfg_read.trialfun               = @ft_trialfun_general;
cfg_read.trialdef.eventtype     = 'STATUS';
cfg_read.trialdef.eventvalue    = 1:2; % event value: 1 for training trials' onset, 2 for testing trials onset
cfg_read.trialdef.prestim       = cfg.prestim;
cfg_read.trialdef.poststim      = cfg.poststim;
cfg_read                        = ft_definetrial(cfg_read);
cfg_read.channel = cfg.channels; % channel 1 is STATUS channel, 64 10/20 cap (biosemi64.lay)
data = ft_preprocessing(cfg_read);

%% Downsample --------------------------------------------------------------------------
cfg_resample = [];
cfg_resample.feedback = 'none';
cfg_resample.resamplefs      = cfg.refs;
cfg_resample.detrend         = cfg.detrend;
cfg_resample.demean          = cfg.demean;

data = ft_resampledata(cfg_resample, data); 

%% Spectral Filters --------------------------------------------------------------------

cfg_specfilt = [];
cfg_specfilt.feedback = 'none';

% highpass filter - use for 0.5hz highpass
cfg_specfilt.hpfilter        = cfg.bp; 
cfg_specfilt.hpfreq          = cfg.bpfreq(1);  

% lowpass filter - use for 100hz lowpass
cfg_specfilt.lpfilter        = cfg.bp; 
cfg_specfilt.lpfreq          = cfg.bpfreq(2); 

% bandstop filter - use for ~50hz notch filter
cfg_specfilt.bsfilter        = cfg.bs; 
cfg_specfilt.bsfreq          = cfg.bsfreq;
cfg_specfilt.bsfiltord       = 4;

data = ft_preprocessing(cfg_specfilt,data);
%% CREATE DATA STRUC

% Extract data matrix
long_data = [data.trial{:}];
[channels, tlength] = size(data.trial{1});
[~, ntrials] = size(data.trial);

data = [];
data.left_el = long_data(1,:);
data.right_el = long_data(2,:);
data.fs = cfg.refs;
data.tlength = tlength;
data.ntrials = ntrials;

end
