function [X, is_outside] = clip(X, lower, upper)


% Find elements less than the lower bound
lower_indices = X < lower;
X(lower_indices) = lower; % Replace with lower bound

% Find elements greater than the upper bound
upper_indices = X > upper;
X(upper_indices) = upper; % Replace with upper bound

is_outside = lower_indices + upper_indices;
end