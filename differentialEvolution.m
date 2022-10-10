function ret_val = differentialEvolution(options)
	if nargin == 0
		options.max_iteration = 1000;
		options.scale_factor_primary = 0.6;
		options.scale_factor_secondary_1 = 0.5;
		options.scale_factor_secondary_2 = 0.3;
		options.crossover_rate = 0.8;
		options.no_dimension = 10;
		options.no_vector = 20;
		options.upper_limit = ones(1, options.no_dimension);
		options.lower_limit = -ones(1, options.no_dimension);
		options.use_previous_population = 0;
		options.use_mutation_scheme = 1;
		options.use_sorted_selection = 0;
		options.print_values = 1;
		options.func_eval = -1;
		options.fitness_func = "objective_func";
		options.functionID = 0;
		options.resultPath = "result.csv";
		ret_val = options;
		return;
	end
	
	% Defining variables
	persistent population;
	global eval_max eval_exceed;

	% Extracting options into local variables
	iter = options.max_iteration;
	F = options.scale_factor_primary;
	F_1 = options.scale_factor_secondary_1;
	F_2 = options.scale_factor_secondary_2;
	Cr = options.crossover_rate;
	no_dimension = options.no_dimension;
	no_vector = options.no_vector;
	u_limit = repmat(options.upper_limit, no_vector, 1);
	l_limit = repmat(options.lower_limit, no_vector, 1);
	prev_flag = options.use_previous_population;
	mutation_switch = options.use_mutation_scheme;
	sort_flag = options.use_sorted_selection;
	print_flag = options.print_values;
	eval_max = options.func_eval;
	eval_exceed = 0;
	fitness = zeros(no_vector, 1);
	fitness_trial = fitness;
	fitness_func = options.fitness_func;
	functionID = options.functionID;
	resultPath = options.resultPath;

	% result and timer
	if print_flag == 2
		initCsv(resultPath);
	end
	init_time = cputime;

	% Initializing population
	if prev_flag == 0 || isempty(population)
		population = l_limit + (u_limit-l_limit).*rand(no_vector, no_dimension);
	elseif prev_flag == 2
		for i = 1: no_vector
			fitness(i) = obj_func(fitness_func, population(i,:), functionID);
		end
		[~, ind] = min(fitness);
		best_vector = population(ind,:);
		population = l_limit + (u_limit-l_limit).*rand(no_vector, no_dimension);
		population(1,:) = best_vector;
	end

	% Evaluating fitness of the individuals
	for i = 1: no_vector
		fitness(i) = obj_func(fitness_func, population(i,:), functionID);
	end

	[best_fitness, ind] = min(fitness);
	best_vector = population(ind,:);

	for iteration = 1: iter
		mutant = population;

		% Mutation
		start_time = cputime;
		for i = 1: no_vector
	   		permutation = randperm(no_vector);
			switch mutation_switch
			case 1
				mutant(i,:) = population(permutation(1),:) + F * ...
       		         		(population(permutation(2),:) - population(permutation(3),:));
            			case 2
            				mutant(i,:) = best_vector + F* ... 
               				(population(permutation(1),:)-population(permutation(2),:));
            			case 3
            				mutant(i,:) = population(i,:) + F1*(best_vector-population(permutation(1),:)) + ... 
               		 		F2*(population(permutation(2),:)-population(permutation(3),:)); 
            			case 4
            				mutant(i,:) = best_vector + ...
            				F1*(population(permutation(1),:)-population(permutation(2),:))+ ...
	                			F2*(population(permutation(3),:)-population(permutation(4),:)); 
            			case 5
            				mutant(i,:) = population(permutation(1),:) + ... 
               		 		F1*(population(permutation(2),:)-population(permutation(1),:))+ ... 
                				F2*(population(permutation(4),:)-population(permutation(5),:)); 
            			otherwise
            				fprintf('\nError:\tMutation scheme not specefied.');
            				fprintf('\nError:\tStopping optimization.\n');
            			end

               			 % Boundary control
           			mutant(i,mutant(i,:) < l_limit(i,:)) = l_limit(i,mutant(i,:) < l_limit(i,:));
	            		mutant(i,mutant(i,:) > u_limit(i,:)) = u_limit(i,mutant(i,:) > u_limit(i,:));
		end

		% Crossover
		rand_mat = rand(no_vector, no_dimension);
		trial = (rand_mat > Cr).*population + (rand_mat <= Cr).*mutant;

		for i = 1: no_vector
			fitness_trial(i) = obj_func(fitness_func, trial(i,:), functionID);
		end

		% Selection
		if sort_flag == 0
			population(fitness_trial < fitness,:) = trial(fitness_trial < fitness,:);
			fitness(fitness_trial < fitness) = fitness_trial(fitness_trial < fitness,:);
			[best_fitness, ind] = min(fitness);
			best_vector = population(ind,:);
		else
			fitness_merged = [fitness; fitness_trial];
			population_merged = [population; trial];
			[~, fitness_index] = sort(fitness_merged);
			population = population_merged(fitness_index(1: no_vector),:);
			fitness = fitness_merged(fitness_index(1: no_vector));
		    	best_vector = population(1,:);
		    	best_fitness = fitness(1);
		end

		end_time = cputime;
		cost_time = end_time - start_time;
		if print_flag == 2
			dumpCsv(resultPath, functionID, iteration, best_fitness, cost_time);
		elseif print_flag == 1
			fprintf('Best fitness at iteration %d is %f, costing %fs by Function %d. \n', iteration, best_fitness, cost_time, functionID);
		end

		if eval_max > 0 && eval_exceed == 1
			break;
		end
	end
	
	val.time_cost = cputime - init_time;
	val.population = population;
	val.best_vector = best_vector;
	val.fitness = fitness;
	val.best_fitness = best_fitness;
	ret_val = val;
	dumpCsv(resultPath, functionID, -1, ret_val.best_fitness, ret_val.time_cost);
	return;
end

% Wrapper for the objective function
function y = obj_func(fitness_func, x, functionID)
	persistent function_evaluations;
	global eval_exceed eval_max;
	if isempty(function_evaluations)
		function_evaluations = 1;
	else
		function_evaluations = function_evaluations + 1;
	end

	if function_evaluations > eval_max
		eval_exceed = 1;
	end
	y = fitness_func(x);
end

% init dump function
function initCsv(resultPath)
	%[folderPath, name, ext] = fileparts(resultPath);
	%if ~isfolder(folderPath)
	%	mkdir(folderPath);
	%end
	%if exist(resultPath, "file")
	%	delete(resultPath);
	%end
	fp = fopen(resultPath, "wt");
		fprintf(fp, "functionID,iteration,best_fitness,cost_time\n");
	fclose(fp);
end

% dump function
function dumpCsv(resultPath, functionID, iteration, best_fitness, cost_time)
	fp = fopen(resultPath, "at");
	if iteration >= 0
		fprintf(fp, "%d,%d,%f,%f\n", functionID, iteration, best_fitness, cost_time);
	else
		fprintf(fp, "%d,All,%f,%f\n", functionID, best_fitness, cost_time);
	end
	fclose(fp);
end
