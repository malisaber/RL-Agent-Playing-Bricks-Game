function [loss, gvec] = Calc_grad(Net, input, targets, actions, ~)

dlX = dlarray(input,"CB");     % C=features, B=batch
Q_targ = dlarray(targets,"B"); % 1×n

% Forward
dlY = forward(Net, dlX);       % k×n

% Select chosen Q-values
idx = sub2ind(size(dlY), actions, 1:size(dlX,2));
Q_pred = dlarray(dlY(idx), "B");

% Loss (must be scalar dlarray)
loss = mse(Q_pred, Q_targ);

% Gradients
gvec = dlgradient(loss, Net.Learnables);

end