function analyzeSameMostConnectedBothGroups(inputFMRI, RegionPF, day, out_path)

%% analyzeSameMostConnectedBothGroups
% This function finds all regions, which are similar connected in both groups. 
% Regarding these regions only, this function finds the most connected regions
% of a seed region for a selected time point. 
% Please enter the seed region without specification of the hemisphere 
% (L-, R-). The table will automatically display both sides.
% You can save the table as analyzeSameMostConnectedBothGroups.csv if you 
% specify an output path as the last input argument.

% Input Arguments
% inputFMRI from mergeFMRIdata_input.m
% RegionPF = Seed Region to examine (as String)
% day = Name of the day as in inputFMRI.days (as String)
% out_path = Output path of the table (as String)

%% Specifications
Sides = ["L ","R "]; % Sides of Region-suffix to analyze
NRegions2analyze = 5; % Finds the N most connected regions

%% Examples
% analyzeSameMostConnectedBothGroups(inputFMRI, "SSs", "P21", "/Users/Username/Desktop/Files")
% analyzeSameMostConnectedBothGroups(inputFMRI, "SSs", "P21")
% Remember to replace the path with an existing path or to just leave it out

%% Do not modify the following lines

if nargin == 3
    inputFMRI.save = 0;
    out_path = "";
else
    inputFMRI.save = 1; % control if figure should be saved
    if ~exist(out_path, 'dir')
        mkdir(out_path)
    end
end

% Day of observation
inputFMRI.days = [day];

% Add path to use getTotalData.m
addpath('./rsfMRI_Processing/')

% Load acronyms
load('../Tools/infoData/acronyms_splitted.mat');

% Find and analyze the N most connected regions
relevantRegionsID = [];
OverallRegionsIDs = NaN * ones(NRegions2analyze, 2);
cache = OverallRegionsIDs;
cache_weight_mean = zeros(NRegions2analyze, 2);
inputFMRI.index=1:98;
[OutStruct] = getTotalData(inputFMRI);

for jj = 1:2 % Left and Right
    Region = strcat(Sides(jj), RegionPF);
    RegID = find(acronyms == Region);
    for ii = 1:2 % Group Number
        averageConnection = nanmean(squeeze(OutStruct.Data(RegID, :, :, 1, ii)), 2);
        [SortedConnWeights, idxSort] = sort(averageConnection); % connections sorted
        relevantRegionsID(:, ii) = idxSort(end-NRegions2analyze+1:end); % take the N biggest connections for both groups (ii)
        cache_sortedConnWeights(:, ii) = SortedConnWeights(end-NRegions2analyze+1:end); % take the weights from these connections for both groups (ii)
    end
    chache = intersect(relevantRegionsID(:, 1), relevantRegionsID(:, 2)); % intersection of groups (ii)
    cache(1:size(chache,1),jj) = chache(:); % intersection of groups with NaNs
    for kk = 1:size(chache,1) % kk = number of intersections
        cache_weight1(kk, jj) = cache_sortedConnWeights(find(relevantRegionsID(:,1)==chache(kk)),1); % Group 1
        cache_weight2(kk, jj) = cache_sortedConnWeights(find(relevantRegionsID(:,1)==chache(kk)),2); % Group 2
        cache_weight_mean(kk, jj) = (cache_weight1(kk, jj)+cache_weight2(kk, jj))/2; % Mean of both Groups
    end
    OverallRegionsIDs(1:length(chache), jj) = chache;
end

% Left acronyms
cache_left = rmmissing(cache(:,1)); % Delete all NaN
cache_left = acronyms(cache_left); % Replace integers with acronyms
cache_left(size(cache_left,1)+1:NRegions2analyze,1)='';
% Make both columns the same size to create a table

% Right acronyms
cache_right = rmmissing(cache(:,2)); 
cache_right = acronyms(cache_right);
cache_right(size(cache_right,1)+1:NRegions2analyze,1)=''; 

% Left mean weights
cache_weight_mean_left = cache_weight_mean(:,1);
% Right mean weights
cache_weight_mean_right = cache_weight_mean(:,2);

[cache_weight_mean_left, cache_leftorder] = sort(cache_weight_mean_left,'descend');
cache_left = cache_left(cache_leftorder);
[cache_weight_mean_right, cache_rightorder] = sort(cache_weight_mean_right,'descend');
cache_right = cache_right(cache_rightorder);

bothGroupsTable = table(cache_left(:), cache_weight_mean_left(:), ...
    cache_right(:), cache_weight_mean_right(:));

bothGroupsTable.Properties.VariableNames{'Var1'} = 'Both Groups Left';
bothGroupsTable.Properties.VariableNames{'Var2'} = 'Weight L Mean';
bothGroupsTable.Properties.VariableNames{'Var3'} = 'Both Groups Right';
bothGroupsTable.Properties.VariableNames{'Var4'} = 'Weight R Mean';
display(bothGroupsTable);

if inputFMRI.save == 1
    writetable(bothGroupsTable,out_path+'/analyzeSameMostConnectedBothGroups.csv');
    disp('Table saved to '+out_path+'/analyzeSameMostConnectedBothGroups.csv');
end

