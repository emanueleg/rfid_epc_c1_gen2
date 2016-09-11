function States = init_reader( Q, M, snr )

States = [];

for ii=1:M
    States.rcvdSignalRN(ii) = 0; % tag to reader RN16 packet
    States.rcvdSignalRNCoded(ii) = {zeros(32, 1)};% tag to reader RN16 Miller coded packet
    States.rcvdSignalEPC(ii) = {zeros(128, 1)}; % tag to reader packet
    States.rcvdSignalEPCcoded(ii) = {zeros(2*128, 1)}; % tag to reader packet
    States.rcvdDecodedEPC{ ii } = {zeros(128, 1)};   
    States.rcvdDecodedRN(ii) = 0;
    States.RNflg(ii) = -1;
    States.EPCflg(ii) = -1;
end
States.rcvdDecoded = [];
States.snr = snr;
States.QParam = Q;

States.cmdOut = []; % Reader command channel

States.lastCommand = 0; % 0-no command; 
                        % 1-Query Command
                        % 2-ACK 
                        % 3-Query Rep
                        
States.CurCommand = 0;  % 0-no command 
                        % 1-Query Command 
                        % 2-ACK 
                        % 3-Query Rep

States.CurCommandStrtTime = 0; % beginning of the command
States.CurCommandEndTime = 0; % end of the command

States.ACK = []; % This holds the RN16 that is sent back
                 % to the tag as an ACK.



