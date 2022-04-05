function y = ggdrnd(mu, sigma, beta, n)
%GGDRND generates random samples from the GGD.
%
%   Y = RANDGGD(MU, SIGMA, BETA, N)
%     Y (double) is a [1xN] vector of random samples.
%     MU (scalar) is the location parameter.
%     SIGMA (scalar) is the variation parameter.
%     BETA (scalar) is the shape parameter.
%     N (scalar) are the number of samples to generate.
%
% References:
%   [1] Gonzalez-Farias, G., Molina, J. A. D., & Rodríguez-Dagnino, 
%       R. M. (2009). Efficiency of the approximated shape parameter 
%       estimator in the generalized Gaussian distribution. IEEE 
%       Transactions on Vehicular Technology, 58(8), 4214-4223.
%
% See Also: GAMRND, GAMMA

if (isinf(beta) || (beta <= 0))
    error('ggdrnd:InvalidShape', ...
        'Shape parameter outside (0, Inf) range.');
end
alpha = sigma * sqrt(gamma(1/beta) / gamma(3/beta)); % Scale
b = 2*(rand(1, n) < 0.5) - 1; % Bernoulli
g = gamrnd(1/beta, 1, 1, n).^(1/beta);
y = mu + (1/sqrt(alpha)) .* g .* b;
y = y(:);

end
