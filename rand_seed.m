load("round_info.mat");

% rand seed
prev_flag = 0;
fp = fopen("config.csv", "rb");
line = fgetl(fp); % Ignore the first line
seed = containers.Map;
while ~feof(fp)
	line = fgetl(fp);
	try
		config = strsplit(line, ",");
		[functionID, LB, UB, dimension_cnt, vector_cnt, objective_func, global_minimum] = deal(config{:});
		% keep type(functionID) is string
		LB = str2double(LB);
		UB = str2double(UB);
		if UB < LB
			UB = LB + UB;
			LB = UB - LB;
			UB = UB - LB;
		end
		if dimension_cnt == "D"
			dimension_cnt = floor(rand(1, 1) * 10) + 1;
		else
			dimension_cnt = str2num(dimension_cnt);
		end
		vector_cnt = str2num(vector_cnt);
	catch errorInfo
		continue;
	end
	
	fitness = zeros(vector_cnt, 1);
	if prev_flag == 2
		for i = 1: vector_cnt
			fitness(i) = obj_func(fitness_func, population(i,:), functionID);
		end
		[~, ind] = min(fitness);
		best_vector = population(ind, :);
		population = LB + (UB - LB) .* rand(vector_cnt, dimension_cnt);
		population(1, :) = best_vector;
	else % Actually prev_flag == 1 do nothing
		population = LB + (UB - LB) .* rand(vector_cnt, dimension_cnt);
	end
	seed(strcat(functionID, "_D")) = dimension_cnt;
	seed(functionID) = population;
end
fclose(fp);
save(strcat(roundFolder, "/seed.mat"), "seed");
fprintf("\nFinished\n\n");

