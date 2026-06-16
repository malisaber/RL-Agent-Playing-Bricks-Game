classdef Bricks_Env < handle
	properties
		gamma;
		Probs;
		hight;
		column;
		base_rwrd;
		cler_rwrd;
		done_rwrd;
		ilgl_rwrd;
		hght_rwrd;
		inv_acts_value;
		
		state_row_len;
		State;
		Action;
		State_length;
		Action_length;
		representation;
		toBinserted;
		Bricks_ID;
		last_trace;
		ID_cntr;
		trace_en;
		first_draw;
		Hist;
		frame_len;
		frame_dur;
		
		fig;
		ax;
		tit_objct;
	end
	
	
	methods
		% Constructor
		function obj = Bricks_Env(	gamma,		Probs,		hight,		...
									column,		base_rwrd,	cler_rwrd,	...
									done_rwrd,	ilgl_rwrd,	hght_rwrd,	...
									frame_dur,	inv_act_val)
			obj.gamma			= gamma;
			obj.Probs			= Probs ./ sum(Probs);
			obj.hight			= hight;
			obj.column			= column;
			obj.base_rwrd		= base_rwrd;
			obj.cler_rwrd		= cler_rwrd;
			obj.done_rwrd		= done_rwrd;
			obj.ilgl_rwrd		= ilgl_rwrd;
			obj.hght_rwrd		= hght_rwrd;
			obj.inv_acts_value	= inv_act_val;
			
			%Initialization
			many				= sum(Probs ~= 0)-1;
			obj.state_row_len	= (many * column - sum(1:(many-1)));
			obj.State			= zeros(hight, obj.state_row_len);
			obj.Action			= zeros(hight, column, column);
			obj.Action_length	= hight * column * column;
			obj.State_length	= hight * obj.state_row_len;
			obj.representation	= zeros(hight+1, column);
			obj.toBinserted		= zeros(1, column);
			obj.Bricks_ID		= zeros(hight+1, column);
			obj.last_trace		= zeros(1, column);
			obj.Hist			= cell(0, 2);
			obj.ID_cntr			= 0;
			obj.trace_en		= false;
			obj.first_draw		= true;
			obj.frame_len		= 1;
			obj.frame_dur		= frame_dur;
			obj.init();
			obj.restart();
		end
		
		
		% checker 
		function checker(obj)
			a = findobj(obj.ax, 'XData', [0 1]);
			if size(a, 1) ~= 0
				disp("fuck");
			end
		end
		
		
		% initialization 
		function init(obj)
			obj.fig = figure('Visible', 'off');
			obj.ax = axes('Parent', obj.fig);
			%obj.ax.YDir = 'reverse';
			obj.ax.XTick = 0:(obj.column);
			obj.ax.YTick = 0:(obj.hight);
			obj.ax.XLim = [-0.5, obj.hight+0.5];
			obj.ax.YLim = [-1.5, obj.hight+0.5];
			hold on;
			grid on;
			obj.draw_frame();
		end
		
		
		% restart function
		function restart(obj)
			if ~isvalid(obj.ax)
				obj.init();
			end
			obj.State			= zeros(obj.hight,		obj.state_row_len);
			obj.representation	= zeros(obj.hight+1,	obj.column);
			obj.toBinserted		= zeros(1, obj.column);
			obj.Bricks_ID		= zeros(obj.hight+1, obj.column);
			obj.last_trace		= zeros(1, obj.column);
			obj.Hist			= cell(0, 2);
			obj.ID_cntr			= 0;
			obj.first_draw		= true;
			obj.insert_row();
			obj.insert_row();
			obj.compile();
			obj.insert_row();
			obj.compile();
			while obj.representation == 0
				obj.insert_row();
			end
		end
		
		
		% Add a new row
		function insert_row(obj)
			row = zeros(1, obj.column);
			trs = zeros(1, obj.column);
			while (sum((row == 0)) == obj.column) || (sum((row ~= 0)) == obj.column)
				row = zeros(1, obj.column);
				trs = zeros(1, obj.column);
				TID = obj.ID_cntr;
				pres_col = 1;
				while pres_col <= obj.column
					prob_bs = rand();
					prob_ac = 0;
					for brick_s=1:size(obj.Probs, 2)
						prob_ac = prob_ac + obj.Probs(1, brick_s);
						if prob_bs < prob_ac
							next_col = pres_col + brick_s - (brick_s > 1) - 1;
							if next_col >= obj.column+1
								continue;
							end
							row(1, pres_col:next_col)	= brick_s-1;
							TID							= TID + (brick_s ~= 1);
							trs(1, pres_col)			= TID * (brick_s ~= 1);
							pres_col = next_col+1;
							break;
						end
					end
				end
			end
			obj.ID_cntr = TID;
			obj.representation(2:(obj.hight+1),:)	= obj.representation(1:obj.hight,:);
			obj.representation(1,:)					= obj.toBinserted;
			obj.toBinserted							= row;
			if obj.trace_en 
				obj.Bricks_ID(2:(obj.hight+1),:)	= obj.Bricks_ID(1:obj.hight,:);
				obj.Bricks_ID(1,:)					= obj.last_trace;
				obj.last_trace						= trs;
			end
		end
		
		
		% compile the representation
		function [comp, rwrd, fail] = compile(obj, comp, rwrd)
			%disp(obj.representation)
			%disp(obj.Bricks_ID)
			hist = cell(50, 2);
			if nargin == 1
				hist(1, 1) = {obj.Bricks_ID};
				hist(1, 2) = {obj.representation};
				hcnt = 2;
				rwrd = 0;
				comp = 1;
			else
				hcnt = size(obj.Hist, 1);
				hist(1:hcnt, :) = obj.Hist;
				hist(hcnt+1, 1) = {obj.Bricks_ID};
				hist(hcnt+1, 2) = {obj.representation};
				hcnt = hcnt + 2;
			end
			hist_en = false;
			done = false;
			while ~done
				done = true;
				for row = 1:size(obj.representation, 1)
					if		sum(obj.representation(row, :))	== 0
						break;
					elseif	sum(obj.representation(row,	:)	== 0) == 0
						obj.representation(row:(end-1),	:)	= obj.representation(row+1:end, :);
						obj.representation(end,			:)	= 0;
						if obj.trace_en 
							obj.Bricks_ID(row:(end-1),	:)	= obj.Bricks_ID(row+1:end, :);
							obj.Bricks_ID(end,			:)	= 0;
						end
						rwrd = rwrd + obj.column * comp;
						comp = 2 * comp;
						done = false;
						hist_en = true;
					end
				end
				if hist_en 
					hist(hcnt, 1)	= {obj.Bricks_ID};
					hist(hcnt, 2)	= {obj.representation};
					hcnt			= hcnt + 1;
					hist_en			= false;
				end
				
				col_done = false;
				while ~col_done
					col_done = true;
					for row = 2:size(obj.representation, 1)
						col_cntr = 1;
						while col_cntr <= obj.column
							brick_size = obj.representation(row, col_cntr);
							if brick_size ~= 0
								if	obj.representation(row-1,	col_cntr:col_cntr+(brick_size-1)) == 0
									obj.representation(row-1,	col_cntr:col_cntr+(brick_size-1)) =  obj.representation	(row,	col_cntr:col_cntr+(brick_size-1));
									obj.representation(row,		col_cntr:col_cntr+(brick_size-1)) =  0;
									done = false;
									col_done = false;
									if obj.trace_en 
										obj.Bricks_ID(row-1,	col_cntr)	=  obj.Bricks_ID		(row,	col_cntr);
										obj.Bricks_ID(row,		col_cntr)	=  0;
									end
								end
							end
							col_cntr = col_cntr + brick_size + (brick_size == 0);
						end
					end
				end
				if ~done 
					hist(hcnt, 1)	= {obj.Bricks_ID};
					hist(hcnt, 2)	= {obj.representation};
					hcnt			= hcnt + 1;
				end
			end
			fail		= sum(obj.representation(end-1,:) ~= 0) ~= 0;
			rwrd		= rwrd + obj.hght_rwrd * sum(sum(obj.representation, 2) ~= 0);
			obj.Hist	= hist(1:hcnt-1, :);
		end
		
		
		% draw the frame
		function draw_frame(obj)
			% plotting the box
			h = obj.hight;
			c = obj.column;
			m = -1;
			% the Box 
			line(obj.ax, [0, 0], [0, h], 'LineWidth', 7.5,	'Marker', 'o', 'MarkerSize', 0.75, 'Tag', 'frame');
			line(obj.ax, [0, c], [0, 0], 'LineWidth', 7.5,	'Marker', 'o', 'MarkerSize', 0.75, 'Tag', 'frame');
			line(obj.ax, [c, c], [0, h], 'LineWidth', 7.5,	'Marker', 'o', 'MarkerSize', 0.75, 'Tag', 'frame');
			line(obj.ax, [0, c], [h, h], 'LineWidth', 7.5,	'Marker', 'o', 'MarkerSize', 0.75, 'Tag', 'frame');
			% the next box
			line(obj.ax, [0, 0], [m, 0], 'LineWidth', 2.5,	'Marker', 'o', 'MarkerSize', 0.75, 'Tag', 'frame', 'LineStyle', '--');
			line(obj.ax, [c, c], [m, 0], 'LineWidth', 2.5,	'Marker', 'o', 'MarkerSize', 0.75, 'Tag', 'frame', 'LineStyle', '--');
			line(obj.ax, [0, c], [m, m], 'LineWidth', 2.5,	'Marker', 'o', 'MarkerSize', 0.75, 'Tag', 'frame', 'LineStyle', '--');
			% title
			obj.tit_objct = title(obj.ax, "#(0), @0, Reward = 0");
		end
		
		
		% draw the Environment state
		function draw_env_state(obj, stt, act, str, BID, TBI)
			colors = ['r', 'g', 'b', 'c', 'm', 'y'];
			if ~isvalid(obj.ax)
				obj.init();
				obj.show();
			end
			rep = obj.S2Rep(reshape(stt, [obj.hight, obj.state_row_len]));
			%disp(BID)
			h = findobj(obj.ax, 'DisplayName', 'state', '-or', 'Tag', 'arrow'); % Finds all line objects (plots) in the current figure
			delete(h);
			[rows, cols] = find(BID ~= 0);
			idxs = sub2ind([obj.hight+1, obj.column], rows, cols);
			brks = rep(idxs);
			for idxs = 1:size(rows,1)
				plot(obj.ax,									...
					[cols(idxs)-0.8, cols(idxs)+brks(idxs)-1.2],...
					[rows(idxs)-0.5, rows(idxs)-0.5],			...
					'LineWidth', 15,							...
					'Marker', 'o',								...
					'MarkerSize', 1.5,							...
					'Color', colors(mod(BID(rows(idxs), cols(idxs)), 6)+1),								...
					'Tag', num2str(BID(rows(idxs), cols(idxs))), ...
					'DisplayName', 'state');
			end
			col = 1;
			while col <= obj.column
				brk_size = TBI(1, col);
				if brk_size ~= 0
					plot(obj.ax,						...
						[col-0.8, col+brk_size-1.2],	...
						[-0.5, -0.5],					...
						'LineWidth', 15,				...
						'Marker', 'o',					...
						'MarkerSize', 1.5,				...
						'Color', 'k',					...
						'Tag', 'TBI',					...
						'DisplayName', 'state');
				end
				col = col + brk_size + (brk_size == 0);
			end
			%for row = 1:obj.hight
			%	col = 1;
			%	row_sum = sum(rep(row, :));
			%	while (col <= obj.column) && (row_sum ~= 0)
			%		brick_size = rep(row, col);
			%		if brick_size ~= 0
			%			plot(obj.ax,							...
			%					[col-0.8, col+brick_size-1.2],	...
			%					[row-0.5, row-0.5],				...
			%					'LineWidth', 15,				...
			%					'Marker', 'o',					...
			%					'MarkerSize', 1.5,				...
			%					'Tag', 'state');
			%		end
			%		col = col + brick_size + (brick_size == 0);
			%	end
			%end
			obj.tit_objct.String = str;
			if ~isempty(act)
				[row_idx, col_idx, col_nxt] = obj.act2idx(act);
				%disp([row_idx, col_idx, col_nxt]);
				%brk_size = rep(row_idx, col_idx);
				%row_cntr = row_idx;
				%for rows = (row_idx-1):-1:1
				%	if rep(rows, col_nxt:(col_nxt+brk_size-1)) ~= 0
				%		row_cntr = rows + 1;
				%		break;
				%	end
				%end
				
				
				
				%if (row_idx == 1) || (row_cntr == row_idx)
				% ah = annotation('arrow');
				% ah.Parent = gca;              % Place in current axes
				% ah.Position = [col_idx-0.8, row_idx-0.5, col_nxt-col_idx, 0];
				% ah.HeadWidth = 25;
				% ah.HeadLength = 25;
				% ah.LineWidth = 4;
				% ah.Color = 'k';
				% ah.Tag = 'arrow';
				%else
				%	plot(obj.ax,					...
				%		[col_idx-0.8, col_nxt-0.8],	...
				%		[row_idx-0.5, row_idx-0.5], ...
				%		'LineWidth', 5,				...
				%		'Marker', 'o',				...
				%		'MarkerSize', 0.75,			...
				%		'Color', 'k',				...
				%		'Tag', 'arrow',				...
				%		'DisplayName', 'state');
				%	ah = annotation('arrow');
				%	ah.Parent = gca;              % Place in current axes
				%	ah.Position = [col_nxt-0.8, row_idx-0.5, 0, (row_cntr-row_idx)];
				%	ah.HeadWidth = 25;
				%	ah.HeadLength = 25;
				%	ah.LineWidth = 4;
				%	ah.Color = 'k';
				%	ah.Tag = 'arrow';
				%end
			end
		end
		
		
		% draw the Environment state (morph)
		function draw_env_state_morph(obj, stt, act, str, BID, TBI, hist)
			if ~isvalid(obj.ax)
				obj.init();
				obj.show();
				obj.draw_env_state(stt, act, str, BID, TBI)
			else
				if obj.first_draw
					obj.draw_env_state(stt, [], str, BID, TBI)
					obj.first_draw = false;
				end
				nBID		= BID;
				rep			= obj.S2Rep(reshape(stt, [obj.hight, obj.state_row_len]));
				siz			= size(hist,1);
				%hist(siz+1, 1) = {obj.Bricks_ID};
				%hist(siz+1, 2) = {obj.representation};
				
				% drow action
				if ~isempty(act)
					obj.move_action(act, BID)
					%[r, c, n] = obj.act2idx(act);
					%disp([r, c, n]);
				end
				drawnow
				for hcnt = 1:siz
					BID		= nBID;
					nBID	= cell2mat(hist(hcnt, 1));
					rep		= cell2mat(hist(hcnt, 2));
					[new_brk, old_brk, die_brk] = obj.Categorize_BIDs(sort(BID(BID ~= 0)), sort(nBID(nBID ~= 0)));
					
					%clc
					%disp("rep")
					%disp(rep);
					%disp("BID")
					%disp(sort(BID(BID ~= 0)));
					%disp("nBID")
					%disp(sort(nBID(nBID ~= 0)));
					%disp("new_brk");
					%disp(new_brk);
					%disp("old_brk");
					%disp(old_brk);
					%disp("die_brk");
					%disp(die_brk);
					
					% clear complete rows 
					%obj.checker();
					obj.clear_bricks(die_brk);
					%obj.checker();
					
					% move old bricks
					obj.move_old_bricks(BID, nBID, old_brk);
					%obj.checker();
					
					% insert new bricks
					obj.insert_bricks(nBID, rep, new_brk);
					%obj.checker();

				end
				
				% drawing TBIs
				obj.draw_TBI(TBI)
				obj.tit_objct.String = str;
			end
		end
		
		
		% move brick duo to action
		function move_action(obj, act, BID)
			[row_idx, col_idx, col_nxt] = obj.act2idx(act);
			act_BID = BID(row_idx, col_idx);
			act_obj = findobj(obj.ax, 'Tag', num2str(act_BID));
			for fl = 1:obj.frame_len
				act_obj.XData = act_obj.XData + (col_nxt - col_idx) / obj.frame_len;
				pause(obj.frame_dur);
				drawnow;
			end
		end
		
		
		% move old bricks
		function move_old_bricks(obj, BID, nBID, old_brk)
			siz		= size(old_brk, 1);
			if siz ~= 0
				tmp		= line();
				old_obj(siz, 1) = tmp;
				delete(tmp);
				prs_row = zeros(siz, 1);
				nxt_row = zeros(siz, 1);
				for oc = 1:siz
					[rows, ~]		= find(nBID == old_brk(oc));
					nxt_row(oc,1)	= rows;
					[rows, ~]		= find( BID == old_brk(oc));
					prs_row(oc,1)	= rows;
					tmp				= findobj(obj.ax, 'Tag', num2str(old_brk(oc)));
					old_obj(oc,:)	= tmp;
				end
				if sum(nxt_row ~= prs_row) ~= 0
					for fl = 1:obj.frame_len
						for oc = 1:size(old_obj, 1)
							old_obj(oc).YData = old_obj(oc).YData + (nxt_row(oc) - prs_row(oc)) / obj.frame_len;
						end
						pause(obj.frame_dur);
						drawnow;
					end
				end
			end
		end
		
		
		% clear complete rows
		function clear_bricks(obj, die_brk)
			siz		= size(die_brk, 1);
			if siz ~= 0
				for oc = 1:siz
					delete(findobj(obj.ax, 'Tag', num2str(die_brk(oc))));
				end
				pause(obj.frame_dur);
				drawnow;
			end
		end
		
		
		% insert new bricks
		function insert_bricks(obj, nBID, rep, new_brk)
			colors	= ['r', 'g', 'b', 'c', 'm', 'y'];
			siz		= size(new_brk, 1);
			if siz ~= 0
				tmp		= line();
				new_obj(siz, 1) = tmp;
				delete(tmp);
				nxt_row = zeros(siz, 1);
				h = findobj(obj.ax, 'Tag', "TBI");
				delete(h);
				for oc = 1:siz
					[rows, cols]	= find(nBID == new_brk(oc));
					brks			= rep(rows, cols);
					if brks == 0
						disp("fuck")
					end
					nxt_row(oc,1)	= rows;
					tmp				= plot(obj.ax,				...
						[cols-0.8,	cols+brks-1.2],				...
						[-0.5,		-0.5],						...
						'LineWidth', 15,						...
						'Marker', 'o',							...
						'MarkerSize', 1.5,						...
						'Color', colors(mod(new_brk(oc), 6)+1),	...
						'Tag', num2str(new_brk(oc)),			...
						'DisplayName', 'state');
					new_obj(oc,:)	= tmp;
				end
				for fl = 1:obj.frame_len
					for oc = 1:size(new_obj, 1)
						new_obj(oc).YData = new_obj(oc).YData + nxt_row(oc) / obj.frame_len;
					end
					pause(obj.frame_dur);
					drawnow;
				end
			end
		end
		
		
		% draw TBI bricks
		function draw_TBI(obj, TBI)
			col = 1;
			while col <= obj.column
				brk_size = TBI(1, col);
				if brk_size ~= 0
					plot(obj.ax,						...
						[col-0.8, col+brk_size-1.2],	...
						[-0.5, -0.5],					...
						'LineWidth', 15,				...
						'Marker', 'o',					...
						'MarkerSize', 1.5,				...
						'Color', 'k',					...
						'Tag', 'TBI',					...
						'DisplayName', 'state');
				end
				col = col + brk_size + (brk_size == 0);
			end
			pause(obj.frame_dur);
			drawnow;
		end
		
		
		% categorize bricks ID
		function [new_brk, old_brk, die_brk] = Categorize_BIDs(~, prs_IDs, nxt_IDs)
			plen		= size(prs_IDs, 1);
			nlen		= size(nxt_IDs, 1);
			len			= max(plen, nlen)+1;
			new_brk		= zeros(len, 1);
			old_brk		= zeros(len, 1);
			die_brk		= zeros(len, 1);
			new_cntr	= 1;
			old_cntr	= 1;
			die_cntr	= 1;
			pcntr		= 1;
			ncntr		= 1;
			while (pcntr <= plen) && (ncntr <= nlen)
				%disp(pcntr)
				%disp(ncntr)
				%disp(prs_IDs(pcntr))
				%disp(nxt_IDs(ncntr))
				if		prs_IDs(pcntr)	<	nxt_IDs(ncntr)
					% died brick
					die_brk(die_cntr)	=	prs_IDs(pcntr);
					die_cntr			=	die_cntr + 1;
					pcntr				=	pcntr	+ 1;
				elseif	prs_IDs(pcntr)	==	nxt_IDs(ncntr)
					% same old brick
					old_brk(old_cntr)	=	prs_IDs(pcntr);
					old_cntr			=	old_cntr + 1;
					pcntr				=	pcntr	+ 1;
					ncntr				=	ncntr	+ 1;
				elseif	prs_IDs(pcntr)	>	nxt_IDs(ncntr)
					% new brick
					new_brk(new_cntr)	=	nxt_IDs(ncntr);
					new_cntr			=	new_cntr + 1;
					ncntr				=	ncntr + 1;
				end
			end
			%disp(new_brk)
			%disp(old_brk)
			%disp(die_brk)
			if pcntr <= plen
				% died brick
				die_brk(die_cntr:die_cntr+(plen-pcntr))	=	prs_IDs(pcntr:end);
				die_cntr				=	die_cntr+(plen-pcntr)+1;
			end
			if ncntr <= nlen
				% new brick
				new_brk(new_cntr:new_cntr+(nlen-ncntr))	=	nxt_IDs(ncntr:end);
				new_cntr				=	new_cntr+(nlen-ncntr)+1;
			end
			new_brk		= new_brk(1:new_cntr-1, 1);
			old_brk		= old_brk(1:old_cntr-1, 1);
			die_brk		= die_brk(1:die_cntr-1, 1);
		end
		
		
		% generate tile 
		function tile = generate_tile(obj, row, block_size)
			tile = zeros(1, obj.column - block_size + 1);
			col = 1;
			while col <= obj.column
				bs = row(1, col);
				if bs == block_size
					tile(1,col) = 1;
					col = col + block_size;
				else
					col = col + bs + (bs == 0);
				end
			end
		end
		
		
		% Row to State function
		function state = Row2S(obj, row)
			Enc_b4 = [];
			Enc_b3 = [];
			Enc_b2 = [];
			Enc_b1 = [];
			if obj.Probs(2) ~= 0, Enc_b1 = obj.generate_tile(row, 1);	end
			if obj.Probs(3) ~= 0, Enc_b2 = obj.generate_tile(row, 2);	end
			if obj.Probs(4) ~= 0, Enc_b3 = obj.generate_tile(row, 3);	end
			if obj.Probs(5) ~= 0, Enc_b4 = obj.generate_tile(row, 4);	end
			state = [Enc_b4, Enc_b3, Enc_b2, Enc_b1];
			if size(state, 2) ~= obj.state_row_len
				error("something went terribly wrong")
			end
		end
		
		
		% Representation to state function
		function state = Rep2S(obj)
			state = zeros(size(obj.State));
			for row=1:obj.hight
				state(row, :) = obj.Row2S(obj.representation(row, :));
			end
		end
		
		
		% row State to row  function
		function row = S2Row(obj, state) 
			t1_e	= obj.state_row_len;
			t1_s	= t1_e - (obj.Probs(2) ~= 0) * (obj.column - 1);
			t2_e	= t1_s - 1;
			t2_s	= t2_e - (obj.Probs(3) ~= 0) * (obj.column - 2);
			t3_e	= t2_s - 1;
			t3_s	= t3_e - (obj.Probs(4) ~= 0) * (obj.column - 3);
			t4_e	= t3_s - 1;
			t4_s	= t4_e - (obj.Probs(5) ~= 0) * (obj.column - 4);
			
			if obj.Probs(5) ~= 0
				Enc_b4 = [state(t4_s:t4_e), 0, 0, 0];	
			else
				Enc_b4 = zeros(1, obj.column); 
			end
			
			if obj.Probs(4) ~= 0
				Enc_b3 = [state(t3_s:t3_e), 0, 0];	
			else
				Enc_b3 = zeros(1, obj.column); 
			end
			
			if obj.Probs(3) ~= 0
				Enc_b2 = [state(t2_s:t2_e), 0];		
			else
				Enc_b2 = zeros(1, obj.column); 
			end
			
			if obj.Probs(2) ~= 0
				Enc_b1 =  state(t1_s:t1_e);			
			else
				Enc_b1 = zeros(1, obj.column); 
			end
			
			row		= zeros(1, obj.column);
			col		= 1;
			while col <= obj.column
				brick_size	=	(4 * Enc_b4(1, col)) + ...
								(3 * Enc_b3(1, col)) + ...
								(2 * Enc_b2(1, col)) + ...
								(1 * Enc_b1(1, col));
				row(1, col:(col + brick_size - (brick_size > 0))) = brick_size;
				col = col + brick_size + (brick_size == 0);
			end
		end
		
		
		% state to representation function
		function rep = S2Rep(obj, state)
			rep = zeros(size(obj.representation));
			for row=1:obj.hight
				rep(row, :) = obj.S2Row(state(row, :));
			end
		end
		
		
		% extract action space
		function Action_space = extract_action_space (obj, rep)
			Action_space	= zeros(1, obj.Action_length);
			Action_cnt		= 1;
			for row = 1:obj.hight
				this_row	= rep(row, :);
				col			= 1;
				while (col <= obj.column) && (sum(this_row) ~= 0)
					brk_siz	= this_row(1, col);
					if brk_siz ~= 0
						act_bas = ((row - 1) * obj.column * obj.column) + ((col - 1) * obj.column);
						[left_space, rght_space] = obj.find_spacing(this_row, col, brk_siz);
						if left_space ~= 0
							Action_space(1, Action_cnt:(Action_cnt+left_space-1)) = ...
								act_bas + ((col-left_space):(col-1));
							Action_cnt = Action_cnt + left_space;
						end
						if rght_space ~= 0
							Action_space(1, Action_cnt:(Action_cnt+rght_space-1)) = ...
								act_bas + ((col+1):(col+rght_space));
							Action_cnt = Action_cnt + rght_space;
						end
					end
					col		= col + brk_siz + (brk_siz == 0);
				end
			end
			Action_space	= Action_space(1, 1:Action_cnt-1);
		end
		
		
		% extract action space of a state 
		function Action_space = extract_state_action_space(obj, state)
			Action_space = cell(size(state, 1), 1);
			for i=1:size(state, 1)
				this_rep			= obj.S2Rep(reshape(state(i, :)', [obj.hight, obj.state_row_len]));
				this_act			= obj.extract_action_space(this_rep);
				Action_space(i, 1)	= {this_act};
			end
		end
		
		
		% convert action space to invlid actions 
		function inv_acts = convert_valid_to_invalid(obj, action_space)
			inv_acts				= 1:obj.Action_length;
			inv_acts(action_space)	= [];
		end
		
		
		% convert action space of a state set to ivalid actions
		function inv_acts = convert_action_set_valid_to_invalid(obj, action_space)
			inv_acts = cell(size(action_space, 1), 1);
			for i=1:size(action_space, 1)
				inv_acts(i) = {obj.convert_valid_to_invalid(cell2mat(action_space(i,1)))};
			end
		end
		
		
		% find origin
		function [col_idx, brk_siz] = find_origin(obj, this_row, col_idx)
			brk_siz = 0;
			if this_row(1, col_idx) ~= 0
				row_dec = zeros(1, obj.column);
				col_cnt = 1;
				while col_cnt <= obj.column
					brick_size = this_row(1, col_cnt);
					if brick_size ~= 0
						row_dec(1, col_cnt) = brick_size;
					end
					col_cnt = col_cnt + brick_size + (brick_size == 0);
				end
				while row_dec(1, col_idx) == 0 && col_idx > 0
					col_idx = col_idx - 1;
				end
				brk_siz = row_dec(1, col_idx);
			end
		end
		
		
		% convert action to its index
		function [row_idx, col_idx, col_nxt] = act2idx(obj, action)
			col_nxt = mod(action-1, obj.column)+1;
			col_idx = mod(floor((action-1)/obj.column), obj.column)+1;
			row_idx	= floor((action-1)/obj.column/obj.column)+1;
		end
		
		
		% find left and right space for a block 
		function [left_space, rght_space] = find_spacing(obj, this_row, col_idx, brk_siz)
			left_space	= 0;
			rght_space	= 0;
			
			% find space
			if brk_siz ~= 0
				% left space
				left_idx	= col_idx - 1;
				while left_idx > 0
					if this_row(1, left_idx) ~= 0
						break;
					end
					left_space	= left_space + 1;
					left_idx	= left_idx - 1;
				end
				% right space
				rght_idx	= col_idx + brk_siz + (brk_siz == 0);
				while rght_idx < obj.column+1
					if this_row(1, rght_idx) ~= 0
						break;
					end
					rght_space	= rght_space + 1;
					rght_idx	= rght_idx + 1;
				end
			end
			
		end
		
		
		% Dynamics
		function [ns, nr, done] = Dynamics(obj, action)
			%	actions:	1:obj.column
			%		1:			(move to Column 1)
			%		2:			(move to Column 2)
			%		3:			(move to Column 3)
			%		4:			(move to Column 4)
			%		5:			(move to Column 5)
			%		6:			(move to Column 6)
			%		7:			(move to Column 7)
			%		8:			(move to Column 8)
			
			
			done		= false;
			[row_idx, col_idx, col_nxt] = obj.act2idx		(action);
			this_row					= obj.representation(row_idx, :);
			[col_idx, brk_siz]			= obj.find_origin	(this_row, col_idx);
			[left_space, rght_space]	= obj.find_spacing	(this_row, col_idx, brk_siz);
			
			% new index
			[new_col_idx, ~] = clip(col_nxt, ...
									max(col_idx-left_space, 0), ...
									min(col_idx+rght_space, obj.column-brk_siz+1));
			illegal = (brk_siz == 0) || (new_col_idx == col_idx);
			
			
			% make the move
			if ~illegal
				this_row(1, col_idx:col_idx+brk_siz-1) = 0;
				this_row(1, new_col_idx:new_col_idx+brk_siz-1) = brk_siz;
				obj.representation(row_idx, :) = this_row;
				obj.Bricks_ID(row_idx, new_col_idx) = obj.Bricks_ID(row_idx, col_idx);
				obj.Bricks_ID(row_idx, col_idx)		= 0;
				[comp, rwrd, ~] = obj.compile();
				obj.insert_row();
				[~,    rwrd, done] = obj.compile(comp, rwrd);
				nr = obj.base_rwrd + obj.cler_rwrd * rwrd + obj.done_rwrd * done;
			else
				nr = obj.ilgl_rwrd;
			end
			
			if obj.representation == 0
				obj.insert_row();
			end
			
			ns = obj.Rep2S();
		end
		
		
		% generate a transition
		function [	episode_this_states,	episode_actions,	episode_rewards,...
					episode_next_states,	terminated] = ...
				generate_transition( ...
					obj,	Net,			Epsilon)
		
			this_state				= obj.Rep2S();
			Action_space			= obj.extract_action_space(obj.representation);
			if rand <= Epsilon
				action_idx			= randi(size(Action_space, 2));
				this_action			= Action_space(action_idx);
			else
				inp					= this_state(:);
				pred				= Net.predict(inp);
				invalid_acts		= obj.convert_valid_to_invalid(Action_space);
				pred(invalid_acts)	= obj.inv_acts_value;
				[~, this_action]	= max(pred);
				this_action			= extractdata(this_action);
			end
			[next_state, next_reward, terminated] = obj.Dynamics(this_action);
			episode_this_states		= this_state(:);
			episode_next_states		= next_state(:);
			episode_actions			= this_action;
			episode_rewards			= next_reward;
		end
		
		
		% Generate an episode
		function [	ep_states,	ep_actions,	ep_rewards,	terminated] = generate_episode(...
					obj, Net, Epsilon, max_length)
			if isinf(max_length) 
				max_length = 1000;
			end
			epi_states	= zeros(max_length+1,	obj.hight * obj.state_row_len);
			epi_actions	= zeros(max_length,		1);
			epi_rewards	= zeros(max_length,		1);
			for step_cntr = 1:max_length
				[ep_s,	ep_a,	ep_r, ep_n,	terminated] = obj.generate_transition(Net,	Epsilon);
				epi_states	(step_cntr, :)		= ep_s;
				epi_actions	(step_cntr, 1)		= ep_a;
				epi_rewards	(step_cntr, 1)		= ep_r;
				if terminated 
					break;
				end
			end
			epi_states		(step_cntr+1, :)	= ep_n;
			ep_states							= epi_states	(1:step_cntr+1,	:);
			ep_actions							= epi_actions	(1:step_cntr,	1);
			ep_rewards							= epi_rewards	(1:step_cntr,	1);
		end
		
		
		% simulate an episode
		function History = simulate(obj, runs, Net,	Epsilon, max_length, sleep_time, flen, start_point)
			obj.trace_en = true;
			obj.show();
			obj.frame_len	= flen;
			if isinf(max_length) 
				max_length = 1000;
			end
			History = cell(runs, 4);
			for run = 1:runs
				rew = 0;
				if isempty(start_point)
					obj.restart();
				else
					obj.define_start_point(start_point);
				end
				BID			= obj.Bricks_ID;
				%TBI			= obj.toBinserted;
				%HST			= obj.Hist;
				run_states	= zeros(max_length+1,	obj.hight * obj.state_row_len);
				run_actions	= zeros(max_length,		1);
				run_rewards	= zeros(max_length,		1);
				for step = 1:max_length
					[ep_s,	ep_a,	ep_r, ep_n,	ep_T] = obj.generate_transition(Net,	Epsilon);
					rew = rew + ep_r;
					str = "#(" + string(run) + "), @" + string(step-1) + ", Reward = " + string(rew);
					run_states	(step, :)	= ep_s;
					run_actions	(step, 1)	= ep_a;
					run_rewards	(step, 1)	= ep_r;
					obj.draw_env_state_morph(ep_s, ep_a, str, BID, obj.toBinserted, obj.Hist);
					BID	= obj.Bricks_ID;
					%TBI	= obj.toBinserted;
					%HST = obj.Hist;
					pause(sleep_time);
					if ep_T 
						break;
					end
				end
				%str = "#(" + string(run) + "), @" + string(step) + ", Reward = " + string(rew);
				%obj.draw_env_state_morph(ep_n, [], str, BID, obj.toBinserted, obj.Hist);
				pause(2*sleep_time);
				run_states		(step+1, :)	= ep_n;
				History(run,1)				= {(run_states	(1:step+1,	:))};
				History(run,2)				= {(run_actions	(1:step,	1))};
				History(run,3)				= {(run_rewards	(1:step,	1))};
				History(run,4)				= {ep_T};
			end
			obj.hide();
			obj.trace_en = false;
			pause(0.01);
		end
		
		
		% extract_state_info
		function [rep, state] = extract_state_info(obj)
			rep		= obj.representation;
			state	= obj.State;
		end
		
		
		% define starting point
		function define_start_point(obj, rep, state)
			if nargin == 3
				obj.representation	= rep;
				obj.State			= state;
			elseif nargin == 2
				obj.representation	= cell2mat(rep(1));
				obj.state			= cell2mat(rep(2));
			elseif nargin == 1
				obj.restart();
			else
				error("Wrong number of inputs");
			end
		end
		
		
		% show the environment
		function show(obj)
			if ~isvalid(obj.ax)
				obj.init();
			end
			obj.fig.Visible = 'on';
		end
		
		
		% hide the Environment
		function hide(obj)
			if ~isvalid(obj.ax)
				obj.init();
			end
			obj.fig.Visible = 'off';
		end
	end
	
end