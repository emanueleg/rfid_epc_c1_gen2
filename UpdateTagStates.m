function [tagStates, rspNum, rdStates] = UpdateTagStates( rdStates, tagStates, t, frmDur, decodeAlg)

if rdStates.CurCommand ~= 0 % a command is fired
    t1 = rdStates.CurCommandStrtTime; % beginning of the command
    t2 = rdStates.CurCommandEndTime;  % end of the command
    rspNum = 0;
    tagONnum = 0;
    
    for ii = 1:length(tagStates)
        [PowState onTime] = inquiryTagPowerState( tagStates(ii), frmDur, t1, t2, t );
        switch PowState
            case 0 % tag is off
                continue;
            case 1 % tag is on
                [tagStates(ii), rsp, rdStates] = EvalTagResponse( onTime, rdStates, tagStates(ii), frmDur, ii, decodeAlg);
            otherwise
                errordlg('Undefined tag power state');
        end
        rspNum = rspNum + rsp;
        tagONnum = tagONnum + PowState;
    end
%     disp(['Num ON tags:', num2str(tagONnum)]);
end
end

function [newTagState, rsp, rdStates] = EvalTagResponse( onTime, rdStates, oldTagStates, frmDur, iCount, decodeAlg)
rsp = 0;
    switch rdStates.CurCommand
        case 0
            % do nothing
        case 1 
            % Query command
            oldTagStates.RN16 = randi(2^16, 1) - 1;
            oldTagStates.RN16coded = EncodeTagMessage(de2bi(oldTagStates.RN16,16), decodeAlg);
            oldTagStates.sltC = round((2^rdStates.QParam)*mod(oldTagStates.RN16/2^rdStates.QParam, 1));
            if oldTagStates.sltC == 0 && onTime>=frmDur.tRN16 % backscatter RN16
                rdStates.rcvdSignalRN(iCount) = oldTagStates.RN16; % backscatter RN16
                rdStates.rcvdSignalRNCoded{iCount} = oldTagStates.RN16coded;
                rdStates.rcvdDecodedRN(iCount) = MSGDecode( oldTagStates.RN16coded, rdStates.snr, oldTagStates.RN16, decodeAlg);

                rdStates.RNflg(iCount) = 1;
                rsp = 1;
            end
        case 2
            % Respond to ACK if valid RN16
            if rdStates.ACK == oldTagStates.RN16 && onTime>=frmDur.tEPC % backscatter EPC
                oldTagStates.EPCcoded = EncodeTagMessage(oldTagStates.EPC, decodeAlg);
                rdStates.rcvdSignalEPC{iCount} = oldTagStates.EPC;
                rdStates.rcvdSignalEPCcoded{iCount} = oldTagStates.EPCcoded;%
                rdStates.rcvdDecodedEPC{ iCount } = MSGDecodeEPC( oldTagStates.EPCcoded, rdStates.snr, oldTagStates.EPC, decodeAlg );
                rdStates.EPCflg(iCount) = 1;
                rsp = 1;
            end
        case 3
            % Respond to Query repeat
            oldTagStates.sltC = mod(oldTagStates.sltC - 1, 2^rdStates.QParam);
            if oldTagStates.sltC == 0 && onTime>=frmDur.tRN16 % backscatter RN16
                rdStates.rcvdSignalRN(iCount) = oldTagStates.RN16; % backscatter RN16
                rdStates.rcvdSignalRNCoded{iCount} = oldTagStates.RN16coded;
                rdStates.rcvdDecodedRN(iCount) = MSGDecode( oldTagStates.RN16coded, rdStates.snr, oldTagStates.RN16, decodeAlg);
                
                rdStates.RNflg(iCount) = 1;
                rsp = 1;                
            end
        otherwise
            errordlg('Wrong command number');
    end
    newTagState = oldTagStates;
end

% This function checks if tag is on within a preiod of t1 to t2.
function  [pwrState, onTime] = inquiryTagPowerState( tagStates, frmDur, t1, t2, current_t )
    % pwrState: 0-tag is not on within [t1,t2]; 1-tag is on within [t1,t2]
    % onTime: 
    if t2-t1 > frmDur.Ton
        pwrState = 0;
        onTime = 0;
        return;
    end
        
    m_on = (tagStates.Vl - tagStates.Vh)/frmDur.Ton;
    m_off = (tagStates.Vh - tagStates.Vl)/frmDur.Toff;
    t1 = tagStates.lastupd + mod( t1 - tagStates.lastupd, frmDur.Ton+frmDur.Toff ); % current time after removing cycles between last update and now
    t2 = tagStates.lastupd + mod( t2 - tagStates.lastupd, frmDur.Ton+frmDur.Toff ); % current time after removing cycles between last update and now
    if tagStates.PowerUp  == 1 % the last update is about when the tag was on
        t_off = (tagStates.Vl-tagStates.Vdc)/m_on + tagStates.lastupd;
        t_onAgain = t_off + frmDur.Toff;
        if (t1<=t_off && t2<=t_off) || (t1>=t_onAgain && t2>=t_onAgain)
            pwrState = 1;
            onTime = mod(t_off - t2, frmDur.Ton+frmDur.Toff);
        else
            pwrState = 0;
            onTime = 0;
        end
        return;        
    elseif tagStates.PowerUp  == 0 % tag is off in the last update
        t_on = (tagStates.Vh-tagStates.Vdc)/m_off + tagStates.lastupd;
        t_offAgain = t_on + Ton;
        if (t1<=t_offAgain && t2 <= t_offAgain) && (t1>=t_on && t2>=t_on)
            pwrState = 1;
            onTime = t_offAgain - t2;
        else
            pwrState = 0;
            onTime = 0;
        end
        return;
    else
        errordlg('Undefined tag power state');
    end

end


function outStream = EncodeTagMessage( inStream, decodeAlg)

    if (decodeAlg == 1)
        outStream = SavazziEncodeTagMessage(inStream, length(inStream));
        outStream = outStream';
        return
    elseif decodeAlg >= 2 

        % This function decodes tag's messages according to Miller 4 coding
        L = length( inStream );
        s1 = [1 1]; % S1 symbol
        s4 = -s1;% S4 symbol
        s2 = [1 -1]; % S2 symbol
        s3 = -s2; 
        outStream = zeros(L,2);

        if inStream(1) == 0
            outStream(1,:) = s1;
            last_sym = 1;
        elseif inStream(1) == 1
            outStream(1,:) = s2;
            last_sym = 2;
        else
            error('error in bit pattern');
        end

        for ii = 2:L
            switch last_sym 
                case 1
                    if inStream(ii) == 0
                        outStream(ii,:) = s4;
                        last_sym = 4;
                    else
                        outStream(ii,:) = s2;
                        last_sym = 2;
                    end
                case 2
                    if inStream(ii) == 0
                        outStream(ii,:) = s4;
                        last_sym = 4;
                    else
                        outStream(ii,:) = s3;
                        last_sym = 3;
                    end
                case 3
                    if inStream(ii) == 0
                        outStream(ii,:) = s1;
                        last_sym = 1;
                    else
                        outStream(ii,:) = s2;
                        last_sym = 2;
                    end
                case 4
                    if inStream(ii) == 0
                        outStream(ii,:) = s1;
                        last_sym = 1;
                    else
                        outStream(ii,:) = s3;
                        last_sym = 3;
                    end
                otherwise
                    errordlg('Somthing is wrong');
            end      
        end

        outStream = outStream';
        outStream = outStream(:);
        return
    end
end



function dcdData = MSGDecode( inStream, snr, actualdata, decodeAlg )
    inStreamNoisy = awgn( inStream, snr, 'measured' );
    inStreamNoisyHard = sign(inStreamNoisy);
    inStreamNoisyHard( inStreamNoisyHard==-1 ) = 0;

    [inStreamNoisyHard, inStreamNoisy];
    
    if decodeAlg == 1
        dcdData = SavazziDecodeTagMessage(inStreamNoisy, length(inStream));
        dcdData = bi2de(dcdData);
        return
    elseif decodeAlg >= 2

        % Trellis structure of Viterbi Decoder
        trellis = [];
        trellis.numInputSymbols = 2;
        trellis.numOutputSymbols=4;
        trellis.numStates = 4;

        trellis.nextStates = [2 1;
                              3 0;
                              3 1;
                              2 0];
        trellis.outputs = [3 2;
                           0 1;
                           0 2;
                           3 1];
        if decodeAlg == 2 
            dcdData = vitdec(inStreamNoisyHard, trellis, 1, 'trunc', 'hard');
            dcdData = bi2de(dcdData');
        elseif decodeAlg == 3
            dcdData = vitdec(-1 .* inStreamNoisy, trellis, 1, 'trunc', 'unquant');
            dcdData = bi2de(dcdData');
        end
        return
    end
end


function dcdData = MSGDecodeEPC( inStream, snr, actualdata, decodeAlg )
    inStreamNoisy = awgn( inStream, snr, 'measured' );
    inStreamNoisyHard = sign(inStreamNoisy);
    inStreamNoisyHard( inStreamNoisyHard==-1 ) = 0;

    if decodeAlg == 1

        dcdData = SavazziDecodeTagMessage(inStreamNoisyHard, length(inStream));
        dcdData = dcdData';
        err = sum(dcdData~=actualdata);
        return
    elseif decodeAlg >= 2

        % Trellis structure of Viterbi Decoder
        trellis = [];
        trellis.numInputSymbols = 2;
        trellis.numOutputSymbols=4;
        trellis.numStates = 4;

        trellis.nextStates = [2 1;
                              3 0;
                              3 1;
                              2 0];
        trellis.outputs = [3 2;
                           0 1;
                           0 2;
                           3 1];
        if decodeAlg == 2 
            dcdData = vitdec(inStreamNoisyHard, trellis, 1, 'trunc', 'hard');
        elseif decodeAlg == 3
            dcdData = vitdec(-1 .* inStreamNoisy, trellis, 1, 'trunc', 'unquant');            
        end
        err = sum(dcdData~=actualdata);       
        return
    end
end