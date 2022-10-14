clear;
clc;
close all;

% initial resutl folder
resultFolder = "figs";
if isfolder(resultFolder)
	rmdir(resultFolder, "s");
end
mkdir(resultFolder);

% options
scheme_folder_struct = dir("scheme*");
function_ID_struct = dir(strcat(scheme_folder_struct(1).name, "/*.csv")); % take the first one as the standard
max_iteration = 100;
x = 0 : 1 : max_iteration;
pauseTime = 0.001;
colors = ["g-" "c-" "y-" "b-" "m-" "g-." "c-." "y-." "b-." "m-." "g--" "c--" "y--" "b--" "m--"];

% initial result
resultFp = fopen("result.csv", "wt");
fprintf(resultFp, "functionID,schemeID,best_fitness,iteration,iteration_time\n");

% walk function_ID
for i = 1 : length(function_ID_struct)
	function_ID_name = function_ID_struct(i).name; % filename
	ms = regexp(function_ID_name, "(?<=\w+)\d+", "match");
	function_ID = str2num(ms{1});
	
	array_best_fitness = zeros(length(scheme_folder_struct), max_iteration + 1);
	array_cost_time = zeros(length(scheme_folder_struct), max_iteration + 1);
	
	% walk scheme folder
	for j = 1 : length(scheme_folder_struct)
		ms = regexp(scheme_folder_struct(j).name, "(?<=\w+)\d+", "match");
		scheme_ID = str2num(ms{1});
		filepath = strcat(scheme_folder_struct(j).name, "/", function_ID_name);
		fp = fopen(filepath, "rt");
		line = fgetl(fp); % Ignore the first line
		k = 1;
		
		% walk file content
		while ~feof(fp) && k <= max_iteration + 1
			line = fgetl(fp);
			result = strsplit(line, ",");
			[functionID, iteration, best_fitness, cost_time] = deal(result{:});
			array_best_fitness(j, k) = str2double(best_fitness);
			array_cost_time(j, k) = str2double(cost_time);
			k = k + 1;
		end
		fclose(fp);
		
		% dump result
		best_fitness = min(array_best_fitness(j, :));
		best_index = min(find(array_best_fitness(j, :) == best_fitness));
		fprintf(resultFp, "%d,%d,%g,%d,%g\n", function_ID, scheme_ID, best_fitness, best_index, sum(array_cost_time(j, 1 : 1 : best_index)));
	end
	
	% draw
	figure("visible", "off");
	hold on;
	for j = 1 : length(scheme_folder_struct)
		plot(x, array_best_fitness(j, :), colors(rem(j, length(colors)) + 1), "LineWidth", 1);
	end
	plot(x, ones(1, max_iteration + 1) * min(min(array_best_fitness)), "r--");
	title(strcat("functionID: ", num2str(function_ID)), "Interpreter", "none");
	legend(scheme_folder_struct.name, "Location", "Best", "Interpreter", "none");
	xlabel("iteration");
	ylabel("best value");
	hold off;
	saveas(gcf, strcat(resultFolder, "/result_", num2str(function_ID), ".jpg"));
	fprintf("Dumped: functionID = %d\n", function_ID);
	clf;
	pause(pauseTime);
end

fclose(resultFp);
fprintf("\nFinished\n\n");