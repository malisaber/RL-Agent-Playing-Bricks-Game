close all force
clear
clc


% set this variable to "true" for using pretrained network for 5X5 game.
load_en			= true; 


% creating foolders
vid_dir			= fullfile("..", "videos");
if ~isfolder(vid_dir),	mkdir(vid_dir),	end


% % Initialization
gamma			= 0.99;

% Probability of different bricks with different sizes, sorted from small
% to large
%                 
%	Brick size:	   empty 1  2  3  4 
Probs			= [1.15, 1, 1, 1, 0];

% Size of the game
hight			= 6;
column			= 5;

% rewards
base_rwrd		= 0.00;			% reward for every step that the agent takes
cler_rwrd		= 1 / column;	% reward for clearing a row
done_rwrd		= -10;			% reward for loosing the game
ilgl_rwrd		= -inf;			% reward for illigal actions (handled internally)
hght_rwrd		= 0;			% reward for stack height


many			= sum(Probs ~= 0)-1;
state_row_siz	= (many * column - sum(1:(many-1)));

% Network Sizes
inp_size		= hight * state_row_siz;
hid_size		= [1024, 512, 256];
out_size		= hight * column * column;


% number of simultions 
sim_cnt = 1;

% Other parameters 
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
sleep_time		= 0.01;
frame_len		= 5;
frame_dur		= 0.1;

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
				step_cntr,		inv_act_val);
	
	net = Net.Net;
	save(	"data.mat",		"DQN_AveRet",		"DQN_Val_AveRet",	...
			"DQN_losses",	"DQN_Val_losses",	"last_episode",		...
			"step_cntr",	"net");
	clear net
else
	load ("data.mat")
	Net.Net = net;
	clear net; 
end


elapsed = toc;
Net.plot_net();
fprintf('Elapsed time of DQN: %.4f seconds\n\n', elapsed);
Env.simulate(sim_cnt,	Net,	0,	ep_len,	sleep_time, frame_len, [], vid_dir);



% comparison
window = 50;
DQN_AveRet_Ts		= movmean(DQN_AveRet,		window, 'Endpoints','fill');
DQN_AveRet_Vs		= movmean(DQN_Val_AveRet,	window, 'Endpoints','fill');
figure; 
title("DQN Average Returns");
hold on;
plot(1:num_episodes, DQN_AveRet_Ts, 'LineWidth', 1);
plot(1:num_episodes, DQN_AveRet_Vs, 'LineWidth', 1);
legend('Training Average','Validation Average','Location','southeast')


