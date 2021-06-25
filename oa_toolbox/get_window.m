function [window, start_idx] = get_window(data, position, w_size)
% function [window] = get_window(data, position, window_size)
% Extracts a window centered around a particular index from a data array
% If the center index is close to the beginning or end of the data array
% the window will be shortened to accommodate for this.
%
% INPUT:
%   * data      - full dataset
%   * position  - position of window center
%   * wsize     - the size of window in samples
%
% OUTPUT:
%   * window    - data window
%   * start_idx - the absolute index of the first sample in the window
start_idx = position - round(w_size/2);
end_idx = position + round(w_size/2) - 1;

if start_idx < 1
    start_idx = 1;
end

if end_idx > numel(data)
    end_idx = numel(data);
end

window = data(start_idx : end_idx);
end

