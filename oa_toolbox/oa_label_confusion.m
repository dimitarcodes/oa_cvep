function [confusion] = oa_label_confusion(true_labels, predicted_labels, criterion)
% function [confusion] = oa_label_confusion(true_labels, predicted_labels, prediction_criterion)
% constructs the confusion matrix of predicted labels and true labels
tl = true_labels;
pl = predicted_labels;
d = criterion;
confusion = [];

%% TRUE LEFT
tleft_indices = (tl == pl & pl == 1);
confusion.tleft_n = sum(tleft_indices);
confusion.tleft_d = d(tleft_indices);

%% FALSE LEFT
fleft_indices = (tl ~= pl & pl == 1);
confusion.fleft_n = sum(fleft_indices);
confusion.fleft_d = d(fleft_indices);

%% TRUE RIGHT
tright_indices = (tl == pl & pl == -1);
confusion.tright_n = sum(tright_indices);
confusion.tright_d = d(tright_indices);

%% FALSE RIGHT
fright_indices = (tl ~= pl & pl == -1);
confusion.fright_n = sum(fright_indices);
confusion.fright_d = d(fright_indices);

end

