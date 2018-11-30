function [model, llh] = logitBin(X, y, lambda, eta)
% Logistic regression for binary classification optimized by Newton-Raphson method.
% Input:
%   X: d x n data matrix
%   z: 1 x n label (0/1)
%   lambda: regularization parameter
%   eta: step size
% Output:
%   model: trained model structure
%   llh: loglikelihood
% Written by Mo Chen (sth4nth@gmail.com).
if nargin < 4
    eta = 1e-1;
end
if nargin < 3
    lambda = 1e-4;
end
X = [X; ones(1,size(X,2))];
[d,n] = size(X);
tol = 1e-4;
epoch = 1000;
llh = -inf(1,epoch);
h = 2*y-1;
w = rand(d,1);
for t = 2:epoch
    a = w'*X;
    %fprintf('Iteration %3d: ',t);
    %llh(t) = -(sum(log1pexp(-h.*a))+0.5*lambda*dot(w,w))/n; % 4.89
    llh(t) = -sum((log1pexp(-a) * y') + (log1pexp(a-1) * (1-y)') + 0.5*lambda*dot(w,w))/n;
    
    %fprintf('LLH %.4f\n', llh(t));
    if abs(llh(t)-llh(t-1)) < tol
        break;
    end
    z = sigmoid(a);                     % 4.87
    g = X*(z-y)'+lambda*w;              % 4.96
    r = z.*(1-z);                       % 4.98
    Xw = bsxfun(@times, X, sqrt(r));
    H = Xw*Xw'+lambda*eye(d);           % 4.97
    w = w-eta*(H\g); 
end
if t == epoch
    fprintf('Iteration limit reached - did not converge\n');
else
    fprintf('Converged after %d iterations\n', t);
end
llh = llh(2:t);
model.w = w;
