function [States, t] = UpdateReaderState( rdStates, t, tCMD )

States = rdStates;

switch rdStates.CurCommand
    case 0
        States.CurCommand = 1; % first Query
        States.CurCommandStrtTime = t;
        States.CurCommandEndTime = t + tCMD.Query;
        t = t + tCMD.Query;
    case 1 % last sent command is Query, 
        if strcmpi(States.rcvdDecoded, 'OneRN')
            States.CurCommand = 2;% ACK
            States.CurCommandStrtTime = t;
            States.CurCommandEndTime = t + tCMD.ACK;
            t = t + tCMD.ACK;
        elseif strcmpi(States.rcvdDecoded, 'NoRN')
            States.CurCommand = 3; % Query Repeition
            States.CurCommandStrtTime = t;
            States.CurCommandEndTime = t + tCMD.QRep;
            t = t + tCMD.QRep;
        elseif strcmpi(States.rcvdDecoded, 'MultiplRN')
            States.CurCommand = 3; % Query Rep
            States.CurCommandStrtTime = t;
            States.CurCommandEndTime = t + tCMD.QRep;
            t = t + tCMD.QRep;
        else
            errordlg('Error in reader decoded message');
        end
    case 2 % ACK
        States.CurCommand = 3;
        t = t + tCMD.QRep;
    case 3 % Query Rep
        if strcmpi(States.rcvdDecoded, 'OneRN')
            States.CurCommand = 2;% ACK
            States.CurCommandStrtTime = t;
            States.CurCommandEndTime = t + tCMD.ACK;
            t = t + tCMD.ACK;
        elseif strcmpi(States.rcvdDecoded, 'NoRN')
            States.CurCommand = 3; % Query Repeition
            States.CurCommandStrtTime = t;
            States.CurCommandEndTime = t + tCMD.QRep;
            t = t + tCMD.QRep;
        elseif strcmpi(States.rcvdDecoded, 'MultiplRN')
            States.CurCommand = 3; % Query Repeition
            States.CurCommandStrtTime = t;
            States.CurCommandEndTime = t + tCMD.QRep;
            t = t + tCMD.QRep;
        else
            errordlg('Error in reader decoded message');
        end        
    otherwise
        errordlg('Error in last command status');
end

M = length(States.rcvdSignalRN);
States.rcvdDecoded = [];
% States.rcvdSignalEPC = zeros(1, M);
for ii = 1:M
    States.rcvdSignalEPC(ii) = {zeros(128, 1)};
    States.rcvdSignalEPCcoded(ii) = {zeros(2*128, 1)}; % tag to reader packet
    States.rcvdSignalRNCoded(ii) = {zeros(32, 1)};% tag to reader RN16 Miller coded packet
    States.rcvdDecodedRN(ii) = 0;
    States.rcvdDecodedEPC( ii ) = {zeros(128, 1)}; 
end
States.rcvdSignalRN = zeros(1, M);
States.RNflg = -ones(1, M);
States.EPCflg = -ones(1, M);