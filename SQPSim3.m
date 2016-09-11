function [TRR TER TTR] = SQPSim3(frmDur, L, M, rau, Tsim, rdr_snr, decodeAlg)

% Generate Query packet and broadcast it to tags
% Each tag decode the message and responds accordingly
% Simulation starts at the beginning of Query commands ignoring for
% duration of selecet command

t = 0; % This holds current time
Vh = 1; %lower voltage threshold
Vl = 0.5; %higher voltage threshold
Q = floor(log2(L));
tagStates = init_tags( M, 'syn', Vl, Vh );
rdStates = init_reader( Q, M, rdr_snr );
nSuccessEPC = 0;
nTentativeEPC = 0;
nErrorEPC = 0;

while t < Tsim
    [rdStates, t] = UpdateReaderState( rdStates, t, frmDur.tCMD );
    [tagStates, rspNum, rdStates] = UpdateTagStates( rdStates, tagStates, t, frmDur, decodeAlg);
    [rdStates t EPCflg] = decodeRcvdMsgRdr( rspNum, rdStates, frmDur, t );
    nSuccessEPC = nSuccessEPC + EPCflg;
    if (rdStates.CurCommand == 2)
        if (EPCflg == 0)
            nErrorEPC = nErrorEPC + 1;
        end
        nTentativeEPC = nTentativeEPC + 1;
    end    
end
TRR = nSuccessEPC / Tsim; %Tag Read Rate
TER = nErrorEPC / Tsim; %Tag Error Rate
TTR = nTentativeEPC / Tsim; %Tag Transmission Rate

end

function [rdStates, t, SuccessEPC] = decodeRcvdMsgRdr( rspNum, rdStates, frmDur, t )
    SuccessEPC = 0;
    if (rdStates.CurCommand==1) || (rdStates.CurCommand==3)
        if rspNum == 1
            rdStates.rcvdDecoded = 'OneRN';
            rdStates.ACK = rdStates.rcvdDecodedRN( rdStates.RNflg ~= -1 );
%             rdStates.ACK = rdStates.rcvdSignalRN( rdStates.RNflg ~= -1 );
            t = t + frmDur.tRN16;
        elseif rspNum==0
            rdStates.rcvdDecoded = 'NoRN';
            t = t + frmDur.tRN16EMP;
        elseif rspNum>1
            rdStates.rcvdDecoded = 'MultiplRN';
            t = t + frmDur.tRN16Cld;
        else
            errordlg('number of tag  responses are not in range');
        end        
    elseif rdStates.CurCommand==2
        if rspNum == 1
            if sum(rdStates.rcvdSignalEPC{rdStates.EPCflg~=-1} ~= rdStates.rcvdDecodedEPC{rdStates.EPCflg~=-1}) == 0
                SuccessEPC = 1;
            else
                SuccessEPC = 0;
            end
            t = t + frmDur.tEPC;
        elseif rspNum == 0 
            SuccessEPC = 0;
            t = t + frmDur.tEPCEMP;
        end
    else
        errordlg('Undefined command code');
    end
end


