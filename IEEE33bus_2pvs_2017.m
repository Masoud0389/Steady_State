clc;
clear;
%%%%%%%%%%%%%%%%% Import PV Data %%%%%%%%%%%%%%%%%%%
pv_data = csvread("pv_data2017.csv", 1, 0);
pv_generation = pv_data(:, 12);
normalized_pv = normalize(pv_generation, "range", [0, 1.5]);
pv_coe = smoothdata(normalized_pv, "sgolay", 10);
%%%%%%%% Time %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
time = readtable("load_data2017.csv");
%time(:, "Time");
Time = time{:, 1};
% ts1 = timeseries(Load_demand, 1:288);
% ts1.TimeInfo.Format = Time;
%%%%%%%%%%%%%%%% Import Load Demand Data %%%%%%%%%%%%%%%
load_data = csvread("load_data2017.csv", 1, 1);
%%%%%%%%%%%%%%%%%% Normalizing Data %%%%%%%%%%%%%%%%%%%%%%%%%%%
load_consumption = load_data(:, 1);
normalized_load = normalize(load_consumption, "range", [0, 2]);
smooth_load = smoothdata(normalized_load, "sgolay", 10);
%%%%%%%%%%%%%%%% Constants %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
array = [];
P_const = [0.1 0.09 0.12 0.06 0.06 0.2 0.2 0.06 0.06 0.04 0.06 0.06 0.12 0.06 0.06 0.06 0.09 0.09 0.09 0.09 0.09 0.09 0.42 0.42 0.06 0.06 0.06 0.12 0.2 0.15 0.21 0.06];
Q_const = [0.06 0.04 0.08 0.03 0.02 0.1 0.1 0.02 0.02 0.03 0.04 0.04 0.08 0.01 0.02 0.02 0.04 0.04 0.04 0.04 0.04 0.05 0.2 0.2 0.03 0.03 0.02 0.07 0.6 0.07 0.1 0.04];
V18_VR = [];
V33_VR = [];
V18 = [];
V33 = [];
%attacker_alpha = 1;
%attacker_beta = 0;
attacker_alpha = 1.05;
attacker_beta = 0.02;
mp_options = mpoption('out.suppress_detail', 1, 'out.sys_sum', 0, 'verbose', 0);
%%%%%%%%%%%%%%%%%%%%%%%%%% Run %%%%%%%%%%%%%%%%%%%%%%%
for i = 1:35040
    define_constants;
    mpc = loadcase('case33bw');
    PPV = -100 * pv_coe(i);
    QPV = 0;
    PPV1 = -100 * pv_coe(i);
    QPV1 = 0;
    for j = 2:33
        mpc.bus (j, PD) = P_const(j-1)*smooth_load(i);
        mpc.bus (j, QD) = Q_const(j-1)*smooth_load(i);
    end
    mpc.bus (18, PD) = ((90*smooth_load(i))+PPV) * 0.001;
    mpc.bus (18, QD) = ((40*smooth_load(i))+QPV) * 0.001;
    mpc.bus (33, PD) = ((60*smooth_load(i))+PPV1) * 0.001;
    mpc.bus (33, QD) = ((40*smooth_load(i))+QPV1) * 0.001;
    [RESULTS, SUCCESS] = runpf(mpc, mp_options);
%%%%%%% FDI Attack %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     for j = 0:364
%     if (i > 84 + 96*j && i < 96*(j+1)) 
%          attacker_alpha = 1.05;
%          attacker_beta = 0.02;
%     else
%          attacker_alpha = 1;
%          attacker_beta = 0;
%     end
%     end
    Vbus_mag = RESULTS.bus(:,8);
    Vbus_mag1(18) = Vbus_mag(18)*attacker_alpha + attacker_beta;
    V18 = [V18; Vbus_mag(18)];
    Vbus_mag1(33) = Vbus_mag(33);
    V33 = [V33; Vbus_mag(33)];
    Vbus_angle = RESULTS.bus(:,9);
    
%%%%%%%  Voltage Regulation %%%%%%%%%%%%%%%%%%%%%%%%%%%
    while Vbus_mag1(18) < 0.95 && QPV > -500
        QPV = QPV - 100;
        mpc.bus (18, QD) = ((40*smooth_load(i))+QPV) * 0.001;
        [RESULTS, SUCCESS] = runpf(mpc, mp_options);
        Vbus_mag = RESULTS.bus(:,8);
    end
    while Vbus_mag1(33) < 0.95 && QPV1 > -500
        QPV1 = QPV1 - 100;
        mpc.bus (33, QD) = ((40*smooth_load(i))+QPV1) * 0.001;
        [RESULTS, SUCCESS] = runpf(mpc, mp_options);
        Vbus_mag = RESULTS.bus(:,8);
    end
    while Vbus_mag1(18) > 1.05 && QPV < 500
        QPV = QPV + 100;
        mpc.bus (18, QD) = ((40*smooth_load(i))+QPV) * 0.001;
        [RESULTS, SUCCESS] = runpf(mpc, mp_options);
        Vbus_mag = RESULTS.bus(:,8);
    end
    while Vbus_mag1(33) > 1.05 && QPV1 < 500
        QPV1 = QPV1 + 100;
        mpc.bus (33, QD) = ((40*smooth_load(i))+QPV1) * 0.001;
        [RESULTS, SUCCESS] = runpf(mpc, mp_options);
        Vbus_mag = RESULTS.bus(:,8);
    end
    V18_VR = [V18_VR; Vbus_mag(18)];
    V33_VR = [V33_VR; Vbus_mag(33)];
    array = [array; Vbus_mag'];
end

%%%%%%% Plot %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% subplot(5,1,1);
% plot(Time,array(:, 18));
% title('Voltage of bus 18 with VR');
% xlabel('Time');
% ylabel('Voltage (pu)');
% 
% subplot(5,1,2);
% plot(Time, V18);
% title('Voltage of bus 18');
% xlabel('Time');
% ylabel('Voltage (pu)');
% 
% subplot(5,1,4);
% plot(Time, V33);
% title('Voltage of bus 33');
% xlabel('Time');
% ylabel('Voltage (pu)');
% 
% subplot(5,1,3); 
% plot(Time, array(:, 33));
% title('Voltage of bus 33 with VR');
% xlabel('Time');
% ylabel('Voltage (pu)');
% 
% subplot(5,1,5); 
% plot(Time, smooth_load);
% title('Load Demand');
% xlabel('Time');
% ylabel('Load demand');
%%%% Creating a dataset %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
csvwrite("VR_dataset_attacked.csv", array)
