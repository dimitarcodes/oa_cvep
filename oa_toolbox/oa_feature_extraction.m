function [source, features] = oa_feature_extraction(data, cfg)
% function [source, features] = oa_feature_extraction(data, cfg)
%
% Extracts features from EEG recording optimized for ocular artefact
% analysis, according to papers [1][2][3].
%
% INPUT:
%   * data - a cell containing eeg data arrays:
%       * data.left_el  - data from electrode on the left side
%       of the head (odd numbered electrodes, use T7, F7 or AF7)
%       * data.right_el - data from electrode on the right side
%       of the head (even numbered electrodes, use T8, F8 or AF8)
%       * data.fs                   - the sampling frequency of the electrode
%       data
%   * cfg - a cell with metadata and configuration:
%       * cfg.sliding_window_size   - the size of the sliding window in
%       seconds (default 1)
%       * cfg.focus_window_size     - the size of the window centered
%       around a high coefficient wavelet in seconds (default0.2)
%       * cfg.verbose               - 0 or 1, whether to print progress 
%       messages (default 1)
%       * cfg.savefile              - 0 or 1, whether to save the extracted
%       features in a file (default 0)
%       * cfg.savename              - string, what to call the file with
%       the features (default "rat.mat")
%
% OUTPUT:
%   *features   - a cell with the extracted features according to [1][2][3]
%       * left_right - Y1 in the references above - left - right channel
%       for maximizing horizontal artefacts and minimizing vertical ones
%       * up_down_blink - Y2 in the references above - left + right channel
%       for maximizing vertical artefacts and minimizing horizontal ones
%       * both of the above have variables:
%           *e - sum of wavelet coefficients, "energy" of each window
%           *m - index of highest wavelet coefficient, an "event window" is
%           centered on this index, within the sliding window (but the
%           indices are converted to be global position)
%           *d - area under the curve using Trapz method of event window
%           signal
%           *a - amplitude of event window signal
%           *v - velocity of artefact in event window
%           *d, a and v _ref - reference values from a window the same size
%           of event window but centered in around the center of the
%           sliding window, providing neutral/unbiased values instead of
%           values near highest wavelet coefficient
%   *source     - a cell with the input signal.
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

%% LOAD VARS
left            = data.left_el;
right           = data.right_el;
fs              = data.fs;
nr_samples      = numel(left);

sliding_window_size = 1; 
sliding_window_step = 0.1; 
focus_window_size   = 0.2;
precomputeY         = 0;
verbose             = 0;
savedata            = 0;
savename            = "rat.mat";

if nargin == 2
    sliding_window_size     = cfg.sliding_window_size;
    focus_window_size       = cfg.focus_window_size;
    verbose                 = cfg.verbose;
    savedata                = cfg.savedata;
    savename                = cfg.savename;
end

slw_size    = round(sliding_window_size*fs);
slw_step    = round(sliding_window_step*fs);
evw_size    = round(focus_window_size*fs);
%% SET UP VARIABLES FOR TRACKING PARAMETERS/FEATURES

features = [];
features.e = zeros(1, nr_samples); % sliding window energy
features.m = zeros(1, nr_samples); % max coefficient value
features.s = zeros(1, nr_samples); % max coefficient sign
features.a = zeros(1, nr_samples); % amplitude around max coefficient
features.d = zeros(1, nr_samples); % trapz around max coefficient

%% SLIDING WINDOW
Y_raw = left - right;

[B,A] = butter(4, 10/(fs/2));
Y  = filter(B,A, Y_raw);

for pos=1:slw_step:nr_samples
    if verbose
        disp("Progress: " + num2str(pos*100/nr_samples) + "% (" + num2str(pos) + " out of " + num2str(nr_samples) + " samples processed)");
    end
    
    % get sliding window window
    [Y_wlp, w_start] = get_window(Y, pos, slw_size);

    % CWT -> sliding window energy, maximum coefficient index
    [features.e(pos), Y_max_coef_idx, Y_max_coef_val, Y_max_coef_sign ] = analyze_sliding_window(Y_wlp, fs);
    theposition = Y_max_coef_idx + w_start - 1;
    features.m(theposition) = Y_max_coef_val;
    features.s(theposition) = Y_max_coef_sign;
    % Extract event
    Y_event = get_window(Y_wlp, Y_max_coef_idx, evw_size);

    % Analyze event
    [features.d(theposition), features.a(theposition), ~] = analyze_event_window(Y_event, fs);
end

source = [];
source.left = left;
source.right = right;
source.Y = Y;
source.fs = fs;

if savedata
   save(savename, 'source', 'features'); 
end

end

