% This mfile is used for simulation of Passive RFID systems under EPC G2C1.
%
% Originally written by: Farzad Hessar
% Email: farzad@u.washington.edu
%
% Modified by: Emanuele Goldoni and Pietro Savazzi
% Email: emanuele.goldoni@unipv.it pietro.savazzi@unipv.it


clc
clear; 
secflg = 1; % select the section in 

% Parameters
fs = 4e6;
BLF = fs/16;
Tari = (2555-2459)/fs; % acquired from measured data
Tpri = 1/BLF;   % duration of one pulse 
RTcal = 3*Tari;

T1 = max(RTcal, 10*Tpri); % inter symbol intervals
T2 = 10/BLF; % inter symbol intervals
T3 = 0; % inter symbol intervals
tQRep = 4291/fs; % duration of one query rep command
tQuery = tQRep; % duration of one query rep command
tACK = 2571/fs; % Duration of sending ACK back to transponder
tRN16 = 2449/fs; % Duration of sending RN16
tEPC = 9640/fs; % duration of one EPC packet

Te = tQRep + T1 + T3;% Duration of empty frame
Tc = tQuery + T1 + tRN16 + T2; % Duration of Collided query
Tia = tQuery+T1+tRN16+T2+tACK+T1+T3;% Duration of invalid ACK frame
Ts = tQuery+T1+tRN16+T2+tACK+T1+tEPC+T2; % duration of successful query command

Ton= 3.8*Ts;     % Duration of active cycle
Toff = 3.2*Ton;  % Duration of standby cycle
rau =  Ton/(Ton+Toff); % duty cycle

M = 12; % number of listening tags
Q = 4; % Query paramter controling the frame size
L = 2^Q; %Range of slot conuter [0 L-1]

SNR = 10; % Signal-to-Noise ratio at the reader (dB)
Perr = 1 - (1-qfunc(sqrt(2*10^(SNR/10))))^16; % Error rate in transmission of RN16
P_eEPC = 1 - (1-qfunc(sqrt(2*10^(SNR/10))))^128; % Error rate in transmission of EPC Packet

frameDurations.Tc = Tc;%1
frameDurations.Te = Te;%1;
frameDurations.Tia = Tia;%2;
frameDurations.Ts = Ts;%5;
frameDurations.Ton = Ton;%30;
frameDurations.Toff = Toff;%40;
frameDurations.tCMD.Query = tQuery;%1;
frameDurations.tCMD.ACK = tACK;%2;
frameDurations.tCMD.QRep = tQRep;%3;%.75e-3;
frameDurations.tRN16 = T1+tRN16+T2;%7 % T1 and T2 are added to account for delays in between
frameDurations.tRN16EMP = T1+T3;%1;
frameDurations.tRN16Cld = T1+tRN16+T2;%5;
frameDurations.tEPC = T1+tEPC+T2;%15;
frameDurations.tEPCEMP = T1+T3;%.0001;



%% TRR
if secflg == 1
% This part simulates tag read rate as a function of T_ON
tstep = Ts/4; %min([Ts, Te, Tc, Tia]);
TON_vect = Ts*[1 2 3 4 5 7 9 11 13 15 19 23 27 31];%logspace(0,1.5,12);%.5*Ts:tstep:20*Ts;
TON_vect = Ts*[1 2 3 4 5 6 7 9 12 17 23 31];%logspace(0,1.5,12);%.5*Ts:tstep:20*Ts;
TON_vect = Ts*[1 2 3 4];%logspace(0,1.5,12);%.5*Ts:tstep:20*Ts;

nsims = 1000;

SNR = [6 7 8 9 10 11 12 13 14 15 16 17 18 19 20];
SNR = [6 8 10 12 14 16 18 20];
TON_vect = 20*Ts; 
VecNAnal = zeros(3, length(SNR));
VecNSim = zeros(3, length(SNR));
VecNSav = zeros(3, length(SNR));
VecNSoftSim = zeros(3, length(SNR));

for ii = 1:length(SNR)
    ii; SNR(ii)
    frameDurations.Ton = TON_vect;

    %rau =  Ton/(Ton+Toff); % duty cycle
    rau = 1;
    tCounter = [0 0 0];
    for jj = 1:nsims
        [sTRR sTER sTTR] = SQPSim3(frameDurations, L, M, rau, TON_vect, SNR(ii), 2);
        tCounter = tCounter + [sTRR sTER sTTR];
    end
    VecNSim(:,ii) = tCounter./nsims;
 
    tCounter = [0, 0, 0];
    for jj = 1:nsims
        [sTRR sTER sTTR] = SQPSim3(frameDurations, L, M, rau, TON_vect, SNR(ii), 3);
        tCounter = tCounter + [sTRR sTER sTTR];
    end
    VecNSoftSim(:,ii) = tCounter./nsims;
    
    tCounter = [0, 0, 0];
    for jj = 1:nsims
        [sTRR sTER sTTR] = SQPSim3(frameDurations, L, M, rau, TON_vect, SNR(ii), 1);
        tCounter = tCounter + [sTRR sTER sTTR];
    end
    VecNSav(:,ii) = tCounter./nsims;
    
    
    rau = 1; % normalized TRR is desired in here: TRR/rau
    Perr = 1 - (1-qfunc(sqrt(2*10^(SNR(ii)/10))))^16; % Error rate in transmission of RN16
    P_eEPC = 1 - (1-qfunc(sqrt(2*10^(SNR(ii)/10))))^128; % Error rate in transmission of EPC Packet
    VecNAnal(1,ii) = SQPAnal(TON_vect, Ts, Te, Tc, Tia, L, M, rau, Perr, P_eEPC);
    VecNAnal(2,ii) = SQPAnal(TON_vect, Ts, Te, Tc, Tia, L, M, rau, 1-Perr, 1-P_eEPC);

end



%%%%%%%%%%%%%%%%%%% ASYMPTOTIC RATE %%%%%%%%%%%%%%%%%%%
Ps = M/L*(1-1/L)^(M-1)*(1-Perr);
Pe = (1-1/L)^M;
Pcd = 1-2^(log2(L)-16);
Pc = (1-Pe-M/L*(1-1/L)^(M-1))*Pcd;
Pia = Pc*(1-Pcd)+Ps*Perr/(1-Perr);
Asymp = (1-P_eEPC)*rau*Ps/(Ps*Ts+Pe*Te+Pc*Tc+Pia*Tia);
%%%%%%%%%%%%%%%%%%%
figure;
if ~ishold(gca); hold; end
%plot(SNR, VecNAnal(1,:), '--*','LineWidth', 2.0);
plot(SNR, VecNSim(1,:), ':^r', 'LineWidth', 2.0);
plot(SNR, VecNSoftSim(1,:), '-.oc', 'LineWidth', 2.0);
plot(SNR, VecNSav(1,:), ':*g', 'LineWidth', 2.0);
%legend('Theory', 'Hard Viterbi', 'Soft Viterbi', 'Savazzi');
legend('Hard Viterbi', 'Soft Viterbi', 'The Proposed Scheme');
grid; xlabel('SNR', 'fontsize', 12.0, 'FontWeight', 'bold'); 
ylabel('Tag Read Rate (tag/sec)', 'fontsize', 12.0, 'FontWeight', 'bold');
set(gca, 'FontSize', 12, 'FontWeight', 'Bold');


figure;
if ~ishold(gca); hold; end
%plot(SNR, VecNAnal(2,:), '--*','LineWidth', 2.0);
plot(SNR, VecNSim(2,:), ':^r', 'LineWidth', 2.0);
plot(SNR, VecNSoftSim(2,:), '-.oc', 'LineWidth', 2.0);
plot(SNR, VecNSav(2,:), ':*g', 'LineWidth', 2.0);
%legend('Theory', 'Hard Viterbi', 'Soft Viterbi', 'Savazzi');
legend('Hard Viterbi', 'Soft Viterbi', 'The Proposed Scheme');
grid; xlabel('SNR', 'fontsize', 12.0, 'FontWeight', 'bold'); 
ylabel('Tag Error Rate (tag/sec)', 'fontsize', 12.0, 'FontWeight', 'bold');
set(gca, 'FontSize', 12, 'FontWeight', 'Bold');

break
end
