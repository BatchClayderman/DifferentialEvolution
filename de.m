load("round_info.mat");

% adjust configs
pauseTime = 1;
population_fixed = 1; % decide whether to have population fixed
load(strcat(roundFolder, "/seed.mat"));

% walk scheme
for use_scheme = 1 : 8
	% folder names
	folderPath = strcat(roundFolder, "/scheme_", num2str(use_scheme));
	if isClear && isfolder(folderPath)
		rmdir(folderPath, "s");
	end
	if ~isfolder(folderPath)
		mkdir(folderPath);
	end
	
	% load config
	configFp = fopen("config.csv", "rt");
	line = fgetl(configFp); % Ignore the first line
	success_cnt = 0;
	valid_cnt = 0;
	total_cnt = 0;
	
	% walk config
	while ~feof(configFp)
		line = fgetl(configFp);
		total_cnt = total_cnt + 1;
		if size(findstr(line, ",")) ~= 6
			fprintf("Invalid line %d with invalid count of separator. \n", total_cnt);
			continue;
		end
		config = strsplit(line, ",");
		
		% Unpack a line
		try
			[functionID, LB, UB, dimension_cnt, vector_cnt, objective_func, global_minimum] = deal(config{:});
			valid_cnt = valid_cnt + 1;
		catch errorInfo
			fprintf("[%d|%d|%d] Line: %d -> %s\n", round_cnt, use_scheme, total_cnt, total_cnt, errorInfo.message);
			pause(pauseTime);
			continue;
		end
		
		functionID = str2num(functionID);
		LB = str2double(LB);
		UB = str2double(UB);
		if UB < LB
			UB = LB + UB;
			LB = UB - LB;
			UB = UB - LB;
		end
		if population_fixed == 1
			dimension_cnt = seed(strcat(num2str(functionID), "_D"));
		else
			if dimension_cnt == "D"
				dimension_cnt = floor(rand(1, 1) * 10) + 1;
			else
				dimension_cnt = str2num(dimension_cnt);
			end
		end
		vector_cnt = str2num(vector_cnt);
		objective_func = inline(strrep(objective_func, "D", num2str(dimension_cnt)));
		
		% adjust options
		options = differentialEvolution;
		% change to specify maximum number of iterations
		options.max_iteration = 2000;
		% change to specify scaling factor (F)
		options.scale_factor_primary = 0.6;
		% change to specify scaling factor (F1)
		options.scale_factor_secondary_1 = 0.5;
		% change to specify scaling factor (F2)
		options.scale_factor_secondary_2 = 0.3;
		% change to specify crossover rate
		options.crossover_rate = 0.8;
		% change to specify no. of dimension
		options.dimension_cnt = dimension_cnt;
		% change to specify no. of vectors
		options.vector_cnt = vector_cnt;
		% change to specify upper limit as row vector
		options.upper_limit = UB * ones(1, options.dimension_cnt);
		% change to specify lower limit as row vector
		options.lower_limit = LB * ones(1, options.dimension_cnt);
		% set to 1 to recycle previous population
		options.use_previous_population = 0;
		% select between 1 - 6, please specify it on var use_scheme
		options.use_mutation_scheme = use_scheme;
		% set to 1 for sorted selection
		options.use_sorted_selection = 0;
		% set to 0 to stop printing answers, 1 to print to console, and 2 to dump into file
		options.print_values = 2;
		% set to maxumum permitted function evaluations if any
		options.func_eval = -1;
		% name of the objective function
		options.fitness_func = objective_func;
		% function ID of the objective function
		options.functionID = functionID;
		% filepath to dump result
		options.resultPath = strcat(folderPath, "/result_", num2str(functionID), ".csv");
		% population
		if population_fixed && isKey(seed, num2str(functionID))
			options.population = seed(num2str(functionID));
		end
		
		try
			ret_val = differentialEvolution(options);
			success_cnt = success_cnt + 1;
			fprintf("\n[%d|%d|%d] FunctionID = %d, LB = %g, UB = %g, D = %d, V = %d, global_minimum = %g, best_fitness = %g, time = %gs\n", round_cnt, use_scheme, total_cnt, functionID, LB, UB, dimension_cnt, vector_cnt, global_minimum, ret_val.best_fitness, ret_val.time_cost);
		catch errorInfo
			fprintf("\n[%d|%d|%d] FunctionID = %d -> %s\n", round_cnt, use_scheme, total_cnt, functionID, errorInfo.message);
		end
		
		pause(pauseTime);
	end

	fclose(configFp);
	fprintf("\nRound: %d\nScheme: %d\nSuccess / Valid / Total = %d / %d / %d\n\n", round_cnt, use_scheme, success_cnt, valid_cnt, total_cnt);
end

fprintf("\nFinished\n\n\n");