function TRR = SQPAnal(Ton, Ts, Te, Tc, Tia, L, M, rau, Perr, P_eEPC)
% Successive Query Protocol
% This subroutine calculates expected number of successful queries for the
% protocol of repeatedly sending query commands.

Ps = M/L*(1-1/L)^(M-1)*(1-Perr);
Pe = (1-1/L)^M;
Pcd = 1-2^(log2(L)-16);
Pc = (1-Pe-M/L*(1-1/L)^(M-1))*Pcd;
Pia = Pc*(1-Pcd)/Pcd+Ps*Perr/(1-Perr);

N_Ton = 0;
for i = 0:floor((Ton-Ts)/Ts) %Ts
    for j=0:floor((Ton-Ts-i*Ts)/Te) %Te
        for k=0:floor((Ton-Ts-i*Ts-j*Te)/Tia) %Tia
            for l=0:floor((Ton-Ts-i*Ts-j*Te-k*Tia)/Tc) %Tc
                N_Ton = N_Ton + factorial(i+j+k+l)/factorial(i)/factorial(j)/factorial(k)/factorial(l)*Ps^i*Pe^j*Pia^k*Pc^l;
            end
        end
    end
end
N_Ton = N_Ton * Ps;
TRR = N_Ton / Ton * rau;
TRR = TRR * (1-P_eEPC);
