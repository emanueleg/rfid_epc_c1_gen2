function outStream = SavazziEncodeTagMessage ( inStream, k )
    c = -ones(k/2,4);
    
    for i = 1:1
        db = inStream;
        db_matrix = reshape(db, 2, k/2)';
        dbc = bi2de(db_matrix);
        
        tx1 = 2*db-1;
        tx2 = c;
        for j = 1:k/2
            tx2(j,dbc(j)+1)=1;
        end
        
        tx2 = reshape(tx2',1,2*k);
        
        outStream = tx2;

    end
end