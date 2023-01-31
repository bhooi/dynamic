function [scores, yhat] = fit_var(Y)

maxLag=8;
[T,nvary]=size(Y);
aicVals=nan(maxLag,1);
for i=1:maxLag
    Xt=[ones(T,1) latMlag(Y,i)];
    % use same number of observations for all estimations
    yt=Y(1+maxLag:end,:);
    xt=Xt(1+maxLag:end,:);

    nobst=size(yt,1);    
    % OLS
%     coefft=(xt\yt)';
    coefft = (pinv(xt)*yt)';
    residt=yt-(coefft*xt')';

    epe=(residt'*residt)/nobst;
    
    aicVal=aicTest(epe,nvary,i,nobst);
    
    aicVals(i,:)=[aicVal];
end;
[mi,nlag]=min(aicVals);
[y,x,alfa,beta,yhat,resid]=varEst(T,Y,nlag);
scores = [nan(nlag,1); sqrt(sum(resid.^2,2))];
assert(length(scores) == size(Y, 1));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [y,x,alfa,beta,yhat,resid]=varEst(T,Y,nlag)

X=[ones(T,1) latMlag(Y,nlag)];
y=Y(1+nlag:end,:);
x=X(1+nlag:end,:);

[nobs,nvary]=size(y);
nvarx=size(x,2);

% OLS
coeff=(pinv(x)*y)';
beta=coeff(:,2:end);
alfa=coeff(:,1);
yhat=(coeff*x')';
resid=y-yhat;
