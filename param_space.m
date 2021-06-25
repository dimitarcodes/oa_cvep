%% PARAMETER SPACE EXPLORATION SCRIPT
% this script's purpose is to explore the parameter space for the ocular
% artefacts extraction procedure, in order to determine the parameter
% values that produce a best trade off of number of saccades detected and 
% and accuracy of gaze prediction


%% RESET + LOAD LIBS

restoredefaultpath;
clear variables;
close all;
clc;

% Root to project content
root = fullfile(filesep, 'Thesis', 'Experiment');

% Add fieldtrip
ft_root = fullfile(root, 'fieldtrip');
addpath(ft_root);

% Add utilities
util_path = genpath(fullfile(root, 'utilities'));
addpath(util_path);

%Add ocular artefacts toolbox
et_root = fullfile(root, 'oa_toolbox');
addpath(et_root)

%%

subecterinos = [];
for subs=1:9
   subecterinos = [subecterinos; strcat('sub-0', num2str(subs))]; 
end
subecterinos = [subecterinos; 'sub-10'];
subecterinos = [subecterinos; 'sub-11'];
subecterinos = [subecterinos; 'sub-12'];


%% search the feature space


lowvars = 900:100:2600;
highvars = 2700:100:5500; 
nl = numel(lowvars);
nh = numel(highvars);
accuracy = zeros(nl, nh);
minacc = zeros(nl,nh);
nsax = zeros(nl,nh);

for l = 1:nl
    cfg = [];
    cfg.lowtresh = lowvars(l);
    for h = 1:nh
        cfg.hightresh = highvars(h);
        comboacc = zeros(1,12*3);
        combonsax = zeros(1, 12*3);
        for subs = 1:12
            subject = subecterinos(subs,:);
            for runner = 1:3
                run = strcat('test_sync_',num2str(runner));
                [~, confusion] = oa_analysis_precomputed(root, subject, run, cfg);
                current_correct = (confusion.soft.tleft_n + ...
                confusion.soft.tright_n);
                current_nsax = (confusion.soft.tleft_n + ...
                confusion.soft.tright_n + confusion.soft.fleft_n + ...
                confusion.soft.fright_n);
                current_acc = current_correct/current_nsax;
                if (subs-1)*3 + runner == 33
                    comboacc((subs-1)*3 + runner) = nan;
                    combonsax((subs-1)*3 + runner) = nan;
                else
                    comboacc((subs-1)*3 + runner) = current_acc;
                    combonsax((subs-1)*3 + runner) = current_nsax;
                end
            end
        end
        [minval, minidx] = min(comboacc);
        comboacc(comboacc == minval) = nan;
        accuracy(l,h) = nanmean(comboacc);
        minacc(l,h) = minidx;
        nsax(l,h) = nanmean(combonsax);
    end
end
%% explore the best one

cfg= [];
cfg.lowtresh = 1300;
cfg.hightresh = 3200;
axe = zeros(1,12*3);
axi = zeros(12,3);
ns = zeros(1,12*3);
tright =[];
tleft = [];
fright = [];
fleft = [];
for subs = 1:12
    subject = subecterinos(subs,:);
    
    accsn = zeros(1,3);
    for runner = 1:3
        run = strcat('test_sync_',num2str(runner));
        [~, confusion] = oa_analysis_precomputed(root, subject, run, cfg);
        current_correct = (confusion.soft.tleft_n + ...
        confusion.soft.tright_n);
        current_nsax = (confusion.soft.tleft_n + ...
        confusion.soft.tright_n + confusion.soft.fleft_n + ...
        confusion.soft.fright_n);
%         fright = [fright confusion.soft.fright_d.'];
%         fleft = [fleft confusion.soft.fleft_d.'];
%         tright = [tright confusion.soft.tright_d.'];
%         tleft = [tleft confusion.soft.tleft_d.'];

        current_acc = current_correct/current_nsax;
        accsn(runner) = current_acc;
        fprintf('%s %s nsax: %d\n', subject, run, current_nsax);
        axe((subs-1)*3 + runner) = current_acc;
        axi(subs, runner) = current_acc;
        ns((subs-1)*3 + runner) = current_nsax;
    end
    fprintf('%s mean accuracy: %f\n', subject, mean(accsn));
end
fprintf('mean mean accuracy: %f\n', mean(mean(axi)));
%%
disp(mean(mean(axi)));
%% 
figure();
histogram(fright, 50, 'DisplayName', 'false right');
hold on;
histogram(fleft, 50, 'DisplayName', 'false left');
legend;
figure();
histogram(tright, 50,'DisplayName', 'true right');
hold on;
histogram(tleft, 50, 'DisplayName', 'true left');
legend;
%%
for subs = 1:12
    subject = subecterinos(subs,:);
    for runner = 1:3
        run = strcat('test_sync_',num2str(runner));
        fprintf('%s %s #sacc: %d soft acc= %f hard acc= %f\n', subject, run,...
            rat(subs, runner, 1),rat(subs, runner, 2), rat(subs, runner, 3));
    end
end
%% 

tfi = nsax == 34;
tfacs = accuracy(tfi);


