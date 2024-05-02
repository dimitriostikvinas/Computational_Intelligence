%% Tikvinas Dimitrios 9998
% Regression Part 1

%%
close all; 
clear all;

% loading the data
data = load('airfoil_self_noise.dat');
preproc=1;

% spitting the data
[trnData,chkData,tstData]=split_scale(data,preproc);   
Perf=zeros(4,4); % initialization of metrics' matrix 

% Evaluation function
Rsq = @(ypred,y) 1-sum((ypred-y).^2)/sum((y-mean(y)).^2);

% FIS with grid partition
myfis(1)=genfis1(trnData,2,'gbellmf','constant');   % 1 
myfis(2)=genfis1(trnData,3,'gbellmf','constant');   % 2
myfis(3)=genfis1(trnData,2,'gbellmf','linear');     % 3 
myfis(4)=genfis1(trnData,3,'gbellmf','linear');     %4



% Training the models and plotting the results
for i = 1:4
    % anfis
    % running for 100 epoches each
    [trnFis,trnError,~,valFis,valError] = anfis(trnData,myfis(i),[100 0 0.01 0.9 1.1],[],chkData);
    
    
    % Membership functions plots
    for j = 1:5 %as many as the features are
        figure();
        plotmf(valFis,'input',j);
        titlos = "Model " + i + " Feature " + j;
        title(titlos);
    end
    
    % Learning curve
    figure();
    grid on;
    plot([trnError valError]);
    xlabel('# of Iterations'); ylabel('Error');
    legend('Training Error','Validation Error');
    titlos = "Model " + i + " Learning Curve ";
    title(titlos);
    
    % Calculating all the wanted metrics, using the tstData to test the
    % model
    Y = evalfis(tstData(:,1:end-1),valFis); 
    R2 = Rsq(Y,tstData(:,end));
    RMSE = sqrt(mse(Y,tstData(:,end)));
    NMSE = 1 - R2; % R2 = 1 - NMSE
    NDEI = sqrt(NMSE);
    Perf(:,i) = [R2; RMSE; NMSE; NDEI];
    
    %Error plot in test data (prediction)
    predict_error = tstData(:,end) - Y; % every row + last column
    figure();
    plot(predict_error);
    grid on;
    xlabel('input');ylabel('Error');
    titlos = "Model " + i + " Prediction Error ";
    title(titlos);
end

% Results Table
varnames={'Model1', 'Model2', 'Model3', 'Model4'};
rownames={'Rsquared' , 'RMSE' , 'NMSE' , 'NDEI'};
Perf = array2table(Perf,'VariableNames',varnames,'RowNames',rownames);


