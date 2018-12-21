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
    coefft=(xt\yt)';
    residt=yt-(coefft*xt')';

    epe=(residt'*residt)/nobst;
    
    aicVal=aicTest(epe,nvary,i,nobst);
    
    aicVals(i,:)=[aicVal];
end;
[mi,nlag]=min(aicVals);
[y,x,alfa,beta,yhat,resid,sigma2hat,bstd,R2,SS,nobs]=varEst(T,Y,nlag);
scores = [nan(nlag,1); sqrt(sum(resid.^2,2))];
assert(length(scores) == size(Y, 1));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [y,x,alfa,beta,yhat,resid,sigma2hat,bstd,R2,SS,nobs]=varEst(T,Y,nlag)

X=[ones(T,1) latMlag(Y,nlag)];
y=Y(1+nlag:end,:);
x=X(1+nlag:end,:);

[nobs,nvary]=size(y);
nvarx=size(x,2);

% OLS
coeff=(x\y)';
beta=coeff(:,2:end);
alfa=coeff(:,1);
yhat=(coeff*x')';
resid=y-yhat;

% ML estimate of covaraince of residuals
Sigma2=(resid'*resid)/nobs;

% Compute some statistics
sige=sqrt(diag((resid'*resid)/(nobs-nvarx)));
bstd=nan(nvary,nvarx);            
sigma2hat=sige(:).^2;
invx=diag(inv(x'*x));
for i=1:nvary 
    bstd(i,:)=sqrt(sigma2hat(i)*invx);            
end;

R2=nan(nvary,1);
m0=eye(nobs)-1/nobs.*ones(nobs);   
ee=diag(resid'*resid);                        
for i=1:nvary                                                 
    R2(i)=1-ee(i)/(y(:,i)'*m0*y(:,i));                        
end;


% Steady state of VAR
% Could alternatively do this by the companion form
%[betac,alfac]=varGetCompForm(beta,alfa,nlag,nvary);
% inv(eye(nlag^2)-betac)*alfac ... and select the nvary first elements
As=0;
for j=1:nlag
    As=As+beta(:,(j-1)*nvary+1:j*nvary);
end
SS=(eye(nvary)-As)\alfa;       

