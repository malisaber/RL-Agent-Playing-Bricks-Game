function loss = huberLoss(yPred, yTrue, delta)
% yPred, yTrue: dlarray of same size
% delta: threshold (usually 1.0)

err = yPred - yTrue;
absErr = abs(err);

quadratic = 0.5 * err.^2;
linear = delta * (absErr - 0.5 * delta);

loss = mean( (absErr <= delta) .* quadratic + (absErr > delta) .* linear );
end