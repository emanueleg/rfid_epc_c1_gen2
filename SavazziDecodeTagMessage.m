function outStream = SavazziDecodeTagMessage ( inStream, k )
    k = k/2;
    
    for i = 1:1        
      
        rx2=inStream;
        
        rx2 = reshape(rx2',4,k/2);
        jj = 1;
        for j = 1:k/2
            [mrx2, ind] = max(rx2(:,j));
            dbcr(jj:jj+1)=de2bi(ind-1,2);
            jj=jj+2;
        end
        
        outStream = dbcr;

    end
end