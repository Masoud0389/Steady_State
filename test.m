% clear;
% clc;
% close all;
% time_slots = zeros(35040, 1);
% 
% %%% Winter
% for i = 1:(4*24*59)
%     time_slots(i) = 1;
% end
% for i = (334*24*4)+1:(365*24*4)
%     time_slots(i) = 1;
% end
% %%% Spring
% for i = (4*24*59)+1:(4*24*151)
%     time_slots(i) = 2;
% end
% %%% Summer
% for i = (4*24*151)+1:(4*24*244)
%     time_slots(i) = 3;
% end
% %%% Fall
% for i = (4*24*244)+1:(4*24*334)
%     time_slots(i) = 4;
% end
% csvwrite("season.csv", time_slots);

% holidays = [];
% for i = 1:35040
%     if mod(fix(i/96), 365) == 0 || 
%         holidays = [holidays; 1];
%     else
%         holidays = [holidays; 0];
%     end
% end
% csvwrite("weakdays.csv", holidays);
label_norm = zeros(1, 35040)';
label_att = ones(1, 35040)';
label = [label_norm;label_att];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
voltage_data_norm = csvread("VR_dataset_normal.csv");
voltage_data_att = csvread("VR_dataset_attacked.csv");
voltage_data = [voltage_data_norm;voltage_data_att];
weakdays = csvread("weakdays.csv");
weakdays = [weakdays;weakdays];
season = csvread("season.csv");
season = [season;season];
load = csvread("load_dataset.csv");
load = [load;load];
DATASET = [voltage_data, load, weakdays, season, label];
DATASET_table = array2table(DATASET, "VariableNames",["V1","V2","V3","V4","V5","V6","V7","V8","V9","V10","V11","V12","V13","V14","V15","V16","V17","V18","V19","V20","V21","V22","V23","V24","V25","V26","V27","V28","V29","V30","V31","V32","V33","load", "weakdays", "season", "label"]);
writetable(DATASET_table, "DATASET1.csv");
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%








