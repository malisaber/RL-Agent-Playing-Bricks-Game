close all force
clear
clc

src_dir			= fileparts(mfilename("fullpath"));
repo_root		= fileparts(src_dir);
addpath(src_dir);
data_file		= fullfile(repo_root, "data.mat");
load_en			= isfile(data_file);



% % Initialization
gamma			= 0.99;
Probs			= [1.15, 1, 1, 1, 0];
hight			= 6;
column			= 5;
base_rwrd		= 0.05;
cler_rwrd		= 0 / column;
done_rwrd		= -10;
ilgl_rwrd		= -inf;
hght_rwrd		= 0;

many			= sum(Probs ~= 0)-1;
state_row_siz	= (many * column - sum(1:(many-1)));
inp_size		= hight * state_row_siz;
hid_size		= [1024, 512, 256];
out_size		= hight * column * column;
alpha			= 0.0005;
delta	 		= 1;
epsilon			= 1;
EDI				= 1;
ED				= 0.999;
ep_len			= inf;
buf_size		= 100000;
batch_size		= 32;
upd_freq		= 1000;
num_episodes	= 10000;
Val_scens		= 1;
inv_act_val		= -1e9;
sleep_time		= 2;
frame_len		= 5;
frame_dur		= 0.2;

% Task 1, Environment
Env = Bricks_Env(	gamma,			Probs,			hight,		...
					column,			base_rwrd,		cler_rwrd,	...
					done_rwrd,		ilgl_rwrd,		hght_rwrd,	...
					frame_dur,		inv_act_val);


Net = Network(inp_size, hid_size, out_size, alpha, delta);
Tar = Network(inp_size, hid_size, out_size, alpha, delta);
Net.initiate();
Tar.initiate();


% DQN 
DQN_AveRet		= [];
DQN_Val_AveRet	= [];
DQN_losses		= [];
DQN_Val_losses	= [];
last_episode	= 0;
step_cntr		= 0;


disp("DQN: ");
tic;
if ~load_en
	%load("data.mat")
	%Net.Net = net;
	[			DQN_AveRet,		DQN_Val_AveRet,	DQN_losses,		...
				DQN_Val_losses,	last_episode,	step_cntr] =	...
		DQN(													...
				Env,			Net,			Tar,			...
				epsilon,		EDI,			ED,				...
				ep_len,			gamma,			buf_size,		...
				batch_size,		upd_freq,		num_episodes,	...
				Val_scens,  	DQN_AveRet, 	DQN_Val_AveRet, ...
				DQN_losses, 	DQN_Val_losses,	last_episode,	...
				step_cntr,		inv_act_val,	repo_root);
	
	net = Net.Net;
	save(	data_file,		"DQN_AveRet",		"DQN_Val_AveRet",	...
			"DQN_losses",	"DQN_Val_losses",	"last_episode",		...
			"step_cntr",	"net");
	clear net
else
	load (data_file)
	Net.Net = net;
	clear net; 
end


elapsed = toc;
Net.plot_net();
fprintf('Elapsed time of DQN: %.4f seconds\n\n', elapsed);
Env.simulate(3,	Net,	0,	ep_len,	sleep_time, frame_len, []);



% comparison
window = 1000;
DQN_AveRet_Ts		= movmean(DQN_AveRet,		window, 'Endpoints','fill');
DQN_AveRet_Vs		= movmean(DQN_Val_AveRet,	window, 'Endpoints','fill');
figure; 
title("DQN Average Returns");
hold on;
plot(1:num_episodes, DQN_AveRet_Ts, 'LineWidth', 1);
plot(1:num_episodes, DQN_AveRet_Vs, 'LineWidth', 1);
legend('Training Average','Validation Average','Location','southeast')


