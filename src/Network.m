classdef Network < handle
	properties
		Inp_size;
		Hid_size;
		Out_size;
		alpha;
		alpha_base;
		delta;
		
		epi_wind;
		epi_Wcntr;
		prev_TotStp;
		Layers;
		Lgraph;
		Net;
		TAvg;
		TSqAvg;
		monitor;
		monitor_en;
	end

	methods
		%	Constructor
		function obj = Network(inp_size, hid_size, out_size, alpha, delta)
			obj.Inp_size	= inp_size;
			obj.Hid_size	= hid_size;
			obj.Out_size	= out_size;
			obj.alpha_base	= alpha;
			obj.alpha		= alpha;
			obj.delta		= delta;
			
			obj.epi_wind	= zeros(8,1);
			obj.epi_Wcntr	= 0;
			obj.prev_TotStp = 0;
			obj.Layers		= [featureInputLayer(inp_size,"Name","state")];
			for i=1:size(obj.Hid_size(:), 1)
				obj.Layers	= [obj.Layers; fullyConnectedLayer(hid_size(i),"Name","fc"+num2str(i))];
				obj.Layers	= [obj.Layers; reluLayer("Name","relu1"+num2str(i))];
			end
			obj.Layers		= [obj.Layers; fullyConnectedLayer(out_size,"Name","q_values")];
			obj.Lgraph		= layerGraph(obj.Layers);
			obj.Net			= dlnetwork(obj.Lgraph);
			obj.monitor_en	= false;
			obj.TAvg   = [];
			obj.TSqAvg = [];
		end

		
		%	Plot the graph
		function plot_net(obj)
			figure;
			plot(obj.Lgraph)
		end

		%	initiate the network
		function initiate(obj, weights)
			if nargin == 2
				obj.Net.Learnables.Value = weights;
			end
		end


		%	Extract the model
		function weights = extract(obj)
			weights = obj.Net.Learnables.Value;
		end


		%	Forward path
		function out = forward(obj, input)
			dlX = dlarray(input,"CB");   % C=features, B=batch
			dlY = forward(obj.Net, dlX); % Output: k × n (Q-values)
			out = dlY;
		end


		%	Predict
		function out = predict(obj, input)
			dlX = dlarray(input,"CB");   % C=features, B=batch
			dlY = forward(obj.Net, dlX); % Output: k × n (Q-values)
			out = dlY;
		end
		

		%	Train the model
		function loss = Train(obj, input, targets, actions, iter)
			obj.alpha = obj.alpha_base / (1 + 0.1 * floor(iter/10000));
			[loss, gradients] = dlfeval(@Calc_grad, obj.Net, input, targets, actions, obj.delta);
			[obj.Net, obj.TAvg, obj.TSqAvg] = adamupdate(...
				obj.Net, gradients, obj.TAvg, obj.TSqAvg, iter, obj.alpha);
			%Update parameters
			%for i = 1:size(obj.Net.Learnables,1)
			%	obj.Net.Learnables.Value{i} = obj.Net.Learnables.Value{i} -...
			%	obj.alpha * gvec.Value{i};
			%end
		end


		%	get action length
		function act_len = get_action_len(obj)
			act_len = obj.Out_size;
		end


		%	get Input length
		function inp_len = get_inp_len(obj)
			inp_len = obj.Inp_size;
		end


		%	Monitor the learning
		function en_monitor(obj)
			obj.monitor			= trainingProgressMonitor;
			obj.monitor.Metrics	= [	"TrainingLoss", ...
									"ValidationLoss", ...
									"TrainingAveRew", ...
									"ValidationAveRew"];
			obj.monitor.Info	= [ "Epoch", ...
									"LearnRate", ...
									"Epsilon", ...
									"TotSteps", ...
									"Epoch_T_Loss", ...
									"Epoch_V_Loss", ...
									"Epoch_T_AveRew", ...
									"Epoch_V_AveRew",...
									"EpisodeLength_T_Ave",...
									"EpisodeLength_V_Ave"];
			obj.monitor.XLabel	=	"Iteration";
			obj.monitor_en	= true;
			
			groupSubPlot(obj.monitor, "Ave Rew", ["TrainingAveRew",	"ValidationAveRew"]);
			groupSubPlot(obj.monitor, "Loss",	 ["TrainingLoss",	"ValidationLoss"]);
		end


		%	Show monitor pannel
		function progress_monitor(obj, loss, val_loss, rews, val_ave_ret, ...
			episode, epsilon, num_episodes, TotSteps, val_lngs)
			%obj.epi_Wcntr = obj.epi_Wcntr + 1;
			%if episode == 1; obj.epi_wind(:,1) = TotSteps; end
			%if obj.epi_Wcntr > 8; obj.epi_Wcntr = 1; end
			%obj.epi_wind(obj.epi_Wcntr) = TotSteps - obj.prev_TotStp;
			if obj.monitor_en
				updateInfo(obj.monitor,...
					Epoch				= num2str(episode) +...
										  " of " + num2str(num_episodes), ...
					LearnRate			= obj.alpha,...
					Epsilon				= epsilon,...
					TotSteps			= TotSteps,...
					Epoch_T_Loss		= loss,...
					Epoch_V_Loss		= val_loss,...
					Epoch_T_AveRew		= rews,...
					Epoch_V_AveRew		= val_ave_ret,...
					EpisodeLength_T_Ave	= TotSteps - obj.prev_TotStp, ...
					EpisodeLength_V_Ave = val_lngs);
				recordMetrics(obj.monitor,episode, ...
					TrainingLoss		= loss, ...
					ValidationLoss		= val_loss, ...
					TrainingAveRew		= rews, ...
					ValidationAveRew	= val_ave_ret);
				obj.monitor.Progress	= 100 * episode/num_episodes;
				obj.prev_TotStp = TotSteps;
			end
		end
		
		
		%	Get policy and Qval
		function [Qval, Pol] = get_policy(obj)
			inp = eye(obj.Inp_size);
			out = obj.predict(inp);
			[Qval, Pol] = max(out);
		end
		
	end
end





