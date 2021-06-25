function [prior] = oa_prior(direction, boostfactor)
% function [prior] = oa_prior(direction, boostfactor)
%
% input:
%   *direction
%      * -1 = right
%      * 0 = none
%      * 1 = left
% returns:
%   * prior -  an array of 36 elements, half of which
%   are equal to 1 and the other half - equal to 1*boostfactor
%   depending on the direction variable.

prior = ones(1,36);

if direction == -1
    prior(17:36) = 1 + boostfactor*1;
elseif direction == 1
    prior(1:16) = 1 + boostfactor*1;
end

%prior = prior/sum(prior);
%prior = ones(1,36);
end

