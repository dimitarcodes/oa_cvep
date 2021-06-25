function [auc, amplitude, velocity] = analyze_event_window(data_window, fs)
% function [auc, amplitude, velocity] = analyze_event_window(data_window, fs)
% performs analysis on a window [possibly] containing an event, returns
% features considered relevant for detecting ocular artefacts, according to
% papers [1] [2] [3] 
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
% doi:https://doi.org/10.1155/2015/653638
%
% INPUT:
%   * data_window   - array with the data
%   * fs            - sampling rate of the data
%
% OUTPUT:
%   * auc           - the area under the curve, calculated using the Trapz
%   method
%   * amplitude     - amplitude (highest-lowest data points)
%   * velocity      - amplitude divided by the time it takes to get from
%   highest to lowest point (index of high - index of low, divided by the
%   sampling rate)

% calculate the AUC using trapezoidal method
auc = trapz(data_window);

% find positive peak
[pos_peak_value, pos_peak_idx] = max(data_window);
% find negative peak 
[neg_peak_value, neg_peak_idx] = min(data_window);

% amplitude - WARNING: huge pos peak followed by huge neg peak = 0
amplitude = abs(pos_peak_value) - abs(neg_peak_value);

% velocity - amplitude/time
velocity = abs(amplitude)/(abs(pos_peak_idx - neg_peak_idx)/fs);
end