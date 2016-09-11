function states = init_tags( numTags, pwrFlg, Vl, Vh )

states = [];
%******* Constants
% Threshold Voltages: Vl, Vh
% states.pwrFla: defines if tag is ON or OFF
% states.Vdc   : holds current value of output dc voltage


for ii = 1:numTags
    if pwrFlg == 'syn'
        states(ii).PowerUp = 1; % 1-ON, 0-OFF
        states(ii).Vdc = Vh;
    elseif pwrFlg == 'asyn'
        states(ii).PowerUp = randi(2,1)-1;
        states(ii).Vdc = Vl + (Vh-Vl)*rand(1);
    else
        errordlg('Error in tag power up state, undefined state.');
    end
    states(ii).EPC = randi(2, 128, 1)-1;
    states(ii).EPCcoded = [];
    states(ii).lastupd = 0; % time of last update
    states(ii).Vh = Vh;
    states(ii).Vl = Vl;
    states(ii).RN16 = [];
    states(ii).RN16coded = [];
    states(ii).sltC = []; % slot counter
end