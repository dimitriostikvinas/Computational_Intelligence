%% Tikvinas Dimitrios 9998
% Classification Part 2
%%
close all; 
clear all;

% Loading the data starting from the second row and column 
% and apply normalization in all the features except the target variable
data = csvread('epileptic_seizure_data.csv',1,1);
norm_data = data(:,1:end-1);
norm_data = normalize(norm_data);
data = [norm_data(:,1:end) data(:,end)];

% Evaluation function 
Rsq = @(ypred,y) 1-sum((ypred-y).^2)/sum((y-mean(y)).^2);

% Due to the cross validation we are about to proceed, we won't split the
% data

% Grid Searching plan
% For the number of kept features we will use the values 5 7 9 11
% and for the clusters's radius 0.2 0.4 0.6 0.8 1

parameters = zeros(4,5,2); % we have 4x5 trials and these x2 due to the 2 parameters we are solving for

parameters(:,:,1) = [5 5 5 5 5; 7 7 7 7 7; 9 9 9 9 9; 11 11 11 11 11];
parameters(:,:,2) = [0.2 0.4 0.6 0.8 1; 0.2 0.4 0.6 0.8 1; 0.2 0.4 0.6 0.8 1; 0.2 0.4 0.6 0.8 1];


% 5-fold cross validation 
k = 5;

% Using the built-in function relief to reduce the number of features
[idx,weights] = relieff(data(:,1:end-1),data(:,end),6);

% counter in order to make0 addmf() work.
mf_name = strings(500000,1);
for i = 1:50000
    mf_name(i) = "mf"+i;
end
counter = 0;
counter2 = 0;

% Matrix to store OA in k-fold
OA_k_fold = zeros(5,1);
rules_k_fold = zeros(5,1);

% Matrix which includes all the OA
all_OA = zeros(4,5);
rules = zeros(4,5);
kept_f = zeros(4,5);

% Grid Search with class dependent
for p = 1:4
    for q = 1:5
        
        
        
        kept_features = parameters(p,q,1);
        radius = parameters(p,q,2);
        % cv partition for the k-fold
        % splitting the data into 80% train and 20% test set 
        part_for_kfold1 = cvpartition(data(:,end),'KFold',5,'Stratify',true);
        
        % Matrix to store the calculated metrics after the cross validation
        % oi metrikes
        metrics_of_cross_val = zeros(k,4);
        
        
        for repetition = 1:part_for_kfold1.NumTestSets
            
            
            % splitting the training data after the cross validation into 60% training
            % and 20% validation set
            midway_training_data = data(training(part_for_kfold1,repetition),:);
            testing_data = data(test(part_for_kfold1,repetition),:);

            % splitting the midway training data into 60% training and 20% testing data
            part_for_kfold2 = cvpartition(midway_training_data(:,end),'KFold',4,'Stratify',true);
            training_data = midway_training_data(training(part_for_kfold2,2),:);
            checking_data = midway_training_data(test(part_for_kfold2,2),:);
            
            % Keeping the features accounted for each iteration in each data set
            training_data = [training_data(:, idx(1:kept_features)) training_data(:,end)];
            checking_data = [checking_data(:, idx(1:kept_features)) checking_data(:,end)];
            testing_data = [testing_data(:, idx(1:kept_features)) testing_data(:,end)];
            
            
            %%Clustering Per Class 
            [c1,sig1]=subclust(training_data(training_data(:,end)==1,:),radius);
            [c2,sig2]=subclust(training_data(training_data(:,end)==2,:),radius);
            [c3,sig3]=subclust(training_data(training_data(:,end)==3,:),radius);
            [c4,sig4]=subclust(training_data(training_data(:,end)==4,:),radius);
            [c5,sig5]=subclust(training_data(training_data(:,end)==5,:),radius);
            num_rules=size(c1,1)+size(c2,1)+size(c3,1)+size(c4,1)+size(c5,1);
            
            %Build FIS From Scratch
            my_fis=newfis('FIS_SC','sugeno');
            
            % Add Input-Output Variables
            names_in = {};%due to keeping each time different number of features
            for i= 1:size(training_data,2)-1
                names_in{i} = "in" + i;
            end
            
            for i= 1:size(training_data,2)-1
                my_fis = addvar(my_fis,'input',names_in{i},[0 1]);
            end
            my_fis=addvar(my_fis,'output','out1',[0 1]);
            
            % Add Input Membership Functions
            for i=1:size(training_data,2)-1
                for j=1:size(c1,1)
                    counter = counter + 1;
                    my_fis=addmf(my_fis,'input',i,mf_name(counter,1),'gaussmf',[sig1(i) c1(j,i)]);
                end
                for j=1:size(c2,1)
                    counter = counter + 1;
                    my_fis=addmf(my_fis,'input',i,mf_name(counter,1),'gaussmf',[sig2(i) c2(j,i)]);
                end
                for j=1:size(c3,1)
                    counter = counter + 1;
                    my_fis=addmf(my_fis,'input',i,mf_name(counter,1),'gaussmf',[sig3(i) c3(j,i)]);
                end
                for j=1:size(c4,1)
                    counter = counter + 1;
                    my_fis=addmf(my_fis,'input',i,mf_name(counter,1),'gaussmf',[sig4(i) c4(j,i)]);
                end
                for j=1:size(c5,1)
                    counter = counter + 1;
                    my_fis=addmf(my_fis,'input',i,mf_name(counter,1),'gaussmf',[sig5(i) c5(j,i)]);
                end
            end
            counter = 0;
            
            %Add Output Membership Functions
            %breaking down the range [0, 1] into 5 parts due to having 5 classes
            params=[zeros(1,size(c1,1)) zeros(1,size(c2,1))+0.25 zeros(1,size(c3,1))+0.5 zeros(1,size(c4,1))+0.75 ones(1,size(c5,1))];
            for i=1:num_rules
                counter = counter + 1;
                my_fis=addmf(my_fis,'output',1,mf_name(counter,1),'constant',params(i));
            end
            counter = 0;
            
            %Add FIS Rule Base 
            ruleList=zeros(num_rules,size(training_data,2));
            for i=1:size(ruleList,1)
                ruleList(i,:)=i;
            end
            ruleList=[ruleList ones(num_rules,2)];
            my_fis=addrule(my_fis,ruleList);
            
            %Train & Evaluate ANFIS 
            %training for 100 epoches
            [trnFis,trnError,~,valFis,valError]=anfis(training_data,my_fis,[100 0 0.01 0.9 1.1],[],checking_data);
             
            Y=evalfis(testing_data(:,1:end-1),valFis);
            Y=round(Y);
             
            for i=1:size(Y,1)
                if Y(i) < 1
                    Y(i) = 1;
                elseif Y(i) > 5
                    Y(i) = 5;
                end
            end
            diff=testing_data(:,end)-Y;
            
            
            Error_matrix = zeros(5); % due to having 5 classeis
            Error_matrix = confusionmat(testing_data(:,end),Y);
            N = size(testing_data,1);
            OA = sum(diag(Error_matrix))/N;
            OA_k_fold(repetition,1) = OA;
            rules_k_fold(repetition,1) = size(valFis.Rules,2);
            
   
            
        end

        % Finding the mean OA after each k-fold instead of the mean error
        all_OA(p,q) = sum(OA_k_fold(:,1))/k;
        kept_f(p,q) = kept_features;
        rules(p,q) = sum(rules_k_fold(:,1))/k;
        
    end
end


% PLOTS
% OA relevant to fuzzy rules
figure();
scatter(reshape(all_OA,1,[]),reshape(rules,1,[])); grid on;
xlabel("Overall Accuracy"); 
ylabel("Number of Rules");
title("Overall Accuracy relevant to Number of Rules ");

% OA relevant to kept features
figure();
scatter(reshape(all_OA,1,[]),reshape(kept_f,1,[])); grid on;
xlabel("Overall Accuracy"); 
ylabel("Number of kept features");
title("Overall Accuracy relevant to Number of kept features ");

% OA relevant to clusters' radius
figure();
scatter(reshape(all_OA,1,[]),reshape(parameters(:,:,2),1,[])); grid on;
xlabel("Overall Accuracy"); 
ylabel("Aktina cluster");
title("Overall Accuracy relevant to clusters' radius ");

% OA surface relevant to radius and kept features parameters
figure();
surf(all_OA(:,:),parameters(:,:,2),parameters(:,:,1)); grid on;
xlabel("Overall Accuracy"); ylabel("aktina_r"); zlabel("Number of features");
title("Surface of OA relevant to cluster's radius and Number of features.");



