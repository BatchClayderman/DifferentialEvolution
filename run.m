clear;
clc;
close all;

isClear = 0; % decide whether to remove previous values
for round_cnt = 1 : 20
	roundFolder = strcat("round_", num2str(round_cnt));
	save("round_info.mat", "round_cnt");
	save("round_info.mat", "roundFolder", "-append");
	save("round_info.mat", "isClear", "-append");
	
	if isClear && isfolder(roundFolder)
		rmdir(roundFolder, "s");
	end
	if ~isfolder(roundFolder)
		mkdir(roundFolder);
	end
	
	rand_seed;
	de;
	draw;
end