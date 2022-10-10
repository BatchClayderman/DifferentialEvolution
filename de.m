clear;
clc;
close all;

pauseTime = 0.001;
folderPath = "result";
if isfolder(folderPath)
	rmdir(folderPath, 's');
end
mkdir(folderPath);

fp = fopen("config.csv", "rb");
line = fgetl(fp); % Ignore the first line
success_cnt = 0;
valid_cnt = 0;
total_cnt = 0;

while ~feof(fp)
	line = fgetl(fp);
	total_cnt = total_cnt + 1;
	if size(findstr(line, ",")) ~= 6
		fprintf("Invalid line %d with invalid count of separator. \n", total_cnt);
		continue;
	end
	config = strsplit(line, ",");
    
	% Unpack a line
	try
		[functionID, LB, UB, no_dimension, no_vector, objective_func, global_minimum] = deal(config{:});
		valid_cnt = valid_cnt + 1;
	catch errorInfo
		fprintf("[%d] Line: %d -> %s\n", total_cnt, total_cnt, errorInfo.message);
		pause(pauseTime);
		continue;
	end
	
	functionID = str2num(functionID);
	LB = str2num(LB);
	UB = str2num(UB);
	if UB < LB
		UB = LB + UB
		LB = UB - LB
		UB = UB - LB
	end
	if no_dimension == "D"
		no_dimension = fix(rand(1, 1) * 10) + 1;
	else
		no_dimension = str2num(no_dimension);
	end
	no_vector = str2num(no_vector);
	objective_func = inline(strrep(objective_func, "D", num2str(no_dimension)));
	
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
	options.no_dimension = no_dimension;
	% change to specify no. of vectors
	options.no_vector = no_vector;
	% change to specify upper limit as row vector
	options.upper_limit = UB*ones(1, options.no_dimension);
	% change to specify lower limit as row vector
	options.lower_limit = LB*ones(1, options.no_dimension);
	% set to 1 to recycle previous population
	options.use_previous_population = 0;
	% select between 1 - 6
	options.use_mutation_scheme = 6;
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
	
	try
		ret_val = differentialEvolution(options);
		success_cnt = success_cnt + 1;
		fprintf("[%d] FunctionID = %d, LB = %g, UB = %g, D = %d, V = %d, global_minimum = %g, best_fitness = %g, time = %gs\n", total_cnt, functionID, LB, UB, no_dimension, no_vector, global_minimum, ret_val.best_fitness, ret_val.time_cost);
	catch errorInfo
		fprintf("[%d] FunctionID = %d, %s\n", total_cnt, functionID, errorInfo.message);
	end
	
	pause(pauseTime);
end

fprintf("\nSuccess / Valid / Total = %d / %d / %d\n\n", success_cnt, valid_cnt, total_cnt);
