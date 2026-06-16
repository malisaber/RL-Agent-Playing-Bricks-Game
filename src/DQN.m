function [	Returns_Ave,	Val_Returns_Ave,	losses,				...
			val_losses,		last_episode,		step_cntr] =		...
	DQN(	Env,			Net,				Tar,				...
			epsilon,		EDI,				ED,					...
			episode_len,	gamma,				buf_size,			...
			batch_size,		update_freq,		num_episodes,		...
			Val_scen_cnt,   Returns_Ave, 		Val_Returns_Ave,	...
			losses,			val_losses,			last_episode,		...
			step_cntr,		inv_action_value,	output_dir)

if nargin < 21 || isempty(output_dir)
	output_dir = pwd;
end
backup_dir = fullfile(output_dir, "Backup");
if ~exist(backup_dir, "dir")
	mkdir(backup_dir);
end


try
	% initialization
	Net.en_monitor();
	drawnow;
	if last_episode == 0
		Returns_Ave		= zeros(num_episodes, 1);
		losses			= zeros(num_episodes, 1);
		Val_Returns_Ave	= zeros(num_episodes, 1);
		val_losses		= zeros(num_episodes, 1);
	else
		Tar.initiate(Net.extract());
		for i=1:last_episode
			if mod(i, EDI) == 0
				epsilon = epsilon * ED;
			end
			Net.progress_monitor(losses(i), val_losses(i), Returns_Ave(i),...
					Val_Returns_Ave(i), i, epsilon, num_episodes, step_cntr, 0);
		end
	end
	Buf					= cell(buf_size+100, 5);
	
	disp("filling the buffer: ");
	cntr = 0;
	BSC			= 1;
	while cntr < (buf_size/10)
		if mod(cntr, 100) == 0
			for i=1:BSC
				fprintf("\b");
			end
			s = num2str(floor(cntr*100/buf_size)) + " %%";
			fprintf(s);
			BSC = size(char(s), 2) - 1;
		end
		
		Env.restart();
		is_TC = false;
		while ~is_TC && (cntr < (buf_size/10))
			[this_state, this_action, this_reward, next_state, is_TC] = ...
				Env.generate_transition(Tar, 1);
			cntr = cntr + 1;
			Buf(cntr,1) = {this_state};
			Buf(cntr,2) = {this_action};
			Buf(cntr,3) = {this_reward};
			Buf(cntr,4) = {next_state};
			Buf(cntr,5) = {is_TC};
		end
	end
	for i=1:(BSC+2)
		fprintf("\b");
	end
	disp(": done!");
	
	
	% loop on episodes
	disp(" ")
	disp("Start Training ...");
	disp("Progress: ")
	fprintf("\tEpisode: ");
	pause(0.5)
	insert_cntr	= cntr;
	BSC			= 0;
	loss		= 0;
	for episode = (last_episode+1):num_episodes 
		for i=1:BSC
			fprintf("\b");
		end
		s = num2str(episode) + " / " +...
			num2str(num_episodes) +	"    Loss: " + ...
			num2str(loss);
		fprintf(s);
		BSC = size(char(s), 2);
	
		% generating the requence
		Env.restart();
		state_cntr	= 0;
		loss		= 0;
		rews		= 0;
		is_TC		= false;
	
		while (~is_TC)  && ~Net.monitor.Stop && (state_cntr < episode_len)
			[this_state, this_action, this_reward, next_state, is_TC] = ...
				Env.generate_transition(Tar, epsilon);
			cntr		= cntr + 1;
			step_cntr	= step_cntr + 1;
			state_cntr	= state_cntr + 1;
			rews		= rews		+ this_reward * (gamma ^ state_cntr);
			insert_cntr	= insert_cntr + 1;
			if insert_cntr	> buf_size, insert_cntr	= 1;		end
			if cntr			> buf_size, cntr		= buf_size;	end
			Buf(insert_cntr,1)	= {this_state};
			Buf(insert_cntr,2)	= {this_action};
			Buf(insert_cntr,3)	= {this_reward};
			Buf(insert_cntr,4)	= {next_state};
			Buf(insert_cntr,5)	= {is_TC};
			
			
			batch_idx	= randperm(cntr,	batch_size);
			Pres_state	= reshape(cell2mat(Buf(batch_idx, 1)), [Net.Inp_size, batch_size])';
			Pres_actin	= cell2mat(Buf(batch_idx, 2));
			Pres_rewrd	= cell2mat(Buf(batch_idx, 3));
			Next_state	= reshape(cell2mat(Buf(batch_idx, 4)), [Net.Inp_size, batch_size])';
			Pres__done	= cell2mat(Buf(batch_idx, 5));
			vlid_actin	= Env.extract_state_action_space(Pres_state);
			invl_action = Env.convert_action_set_valid_to_invalid(vlid_actin);
			
			Tar_NQVs = Tar.forward(Next_state');
			for bcntr=1:batch_size
				Tar_NQVs(cell2mat(invl_action(bcntr,1)),bcntr) = dlarray(inv_action_value);
			end
			Tar_Qval = Pres_rewrd' + ...
				gamma * max(Tar_NQVs) .* (1-Pres__done');
			stp_loss =  Net.Train(	Pres_state', Tar_Qval, Pres_actin', step_cntr);
			loss = loss + stp_loss;
			
			if mod(step_cntr, update_freq) == 0
				Tar.initiate(Net.extract());
			end
		end
		
		%	Validating
		val_ave_ret	= 0;
		val_loss	= 0;
		val_lngs	= 0;
		for val_cntr = 1:Val_scen_cnt
			Env.restart();
			Net_isdone = false;
			while (~Net_isdone) && (val_ave_ret >= -320) && (val_lngs < 100)
				[~, ~, Net_rewards, ~, Net_isdone] = ...
					Env.generate_transition(Net, 0);
				val_ave_ret = val_ave_ret	+ Net_rewards * (gamma ^ val_lngs);
				val_lngs	= val_lngs		+ 1;
			end
		end
		val_ave_ret = val_ave_ret	/ Val_scen_cnt;
		val_loss	= val_loss		/ Val_scen_cnt;
		val_lngs	= val_lngs		/ Val_scen_cnt;
		
		
		loss						= loss/state_cntr;
		Returns_Ave(episode,1)		= rews;
		losses(episode,1)			= extractdata(loss);
		Val_Returns_Ave(episode,1)	= val_ave_ret;
		val_losses(episode,1)		= val_loss;
		
		Net.progress_monitor(extractdata(loss), val_loss, rews,...
					val_ave_ret, episode, epsilon, num_episodes, step_cntr, val_lngs);
		
		
		if  Net.monitor.Stop
			break;
		end
		
		if mod(episode, 100) == 0
			net = Net.Net;
			name = fullfile(backup_dir, "data_back_" + num2str(episode) + ".mat");
			save(name,	"Returns_Ave",	"Val_Returns_Ave",	"losses",	...
						"val_losses",	"episode",			"step_cntr",...
						"net");
		end
		
		if mod(episode, EDI) == 0
			epsilon = epsilon * ED;
		end
	end
	
	
	last_episode = episode;
	disp(" ")
catch ME
	disp(ME);
	net = Net.Net;
		name = fullfile(backup_dir, "data_back_last.mat");
		save(name,	"Returns_Ave",	"Val_Returns_Ave",	"losses",	...
					"val_losses",	"episode",			"step_cntr",...
					"net");
		rethrow(ME);
end
end




