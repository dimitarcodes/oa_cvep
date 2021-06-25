function [overall_energy, max_energy_index, max_energy_value, max_energy_sign] = analyze_sliding_window(data_window, fs)
% function [overall_energy, max_energy_index] =
% analyze_sliding_window(data_window, fs)
% analyze a window of data using continuous wavelet transform with Haar
% wavelet and scale parameter a=20, inspired by papers [1] [2] [3]
% 
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
%
% INPUT:
%   * data_window   - a window of data to be analyzed
%   * fs            - the sampling rate at which the data was recorded
%
% OUTPUT:
%   * overall_energy    - the sum of squared coefficients 
%   * max_energy_idx    - the index of the largest CWT coefficient
coefs = cwt(data_window, 20, 'haar', fs);
coefs_squared = abs(coefs.*coefs);
overall_energy = sum(coefs_squared(:));

% find index of max energy
%[max_energy_value,max_energy_index] = max(sum(coefs_squared));
[max_energy_value,max_energy_index] = max(coefs_squared);
max_energy_sign = sign(coefs(max_energy_index));
end

    