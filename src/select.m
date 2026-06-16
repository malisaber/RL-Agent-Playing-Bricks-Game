function QV = select(QVs, act)

QV = zeros(size(QVs, 2), 1);
for i = 1:size(QVs, 2)
	QV(i,1) = QVs(act(i,1), i);
end

end