function output = acn(signal, SNR, type)
% Additive Colored Noise with user specified dB contamination.
%
% OUTPUT = ACN(SIGNAL, SNR, TYPE)
%   SIGNAL (double) is the input signal to contaminate.
%   SNR (double) is a scalar of decibel contamination.
%   TYPE (char) is the type of noise to apply.
%
% Contact: Jordan R. Smith

if (~ischar(type))
  error('GitLAB:util:acn:InvalidInput', ...
    'Input TYPE must be type CHAR.');
elseif (~isscalar(SNR) || ~isdouble(SNR))
  error('GitLAB:util:acn:InvalidInput', ...
    'Input SNR must be a scalar power decibel.');
end

% re-orient input signal.
input = signal(:).';
if (size(signal, 2) ~= 1)
    error('GitLAB:util:acn:InvalidInput', ...
        'Input SIGNAL must be a unidimensional signal.');
end
npts = numel(input);

% determine signal and noise power.
signal_power = var(input - mean(input));
noise_power  = signal_power / (10^(SNR/10));

switch type
    case 'pink'
        noisegen = pinknoise(npts);
    case 'violet'
        noisegen = violetnoise(npts);
    case 'red'
        noisegen = rednoise(npts);
    case 'blue'
        noisegen = bluenoise(npts);
    otherwise
        error('GitLAB:util:acn:InvalidInput', ...
            'Unrecognized noise type "%s".', type);
end % switch

% delegate the appropriate noise level.
noisegen = noisegen - mean(noisegen);   % mu = 0.
output = noisegen / std(noisegen)*sqrt(noise_power);
return;
end % acn

%----------------------------------------------------
%               rednoise
%----------------------------------------------------
function y = rednoise(N)

% function: y = rednoise(N)
% N - number of samples to be returned in a row vector.
% Y - a row vector of red (Brownian) noise samples.
%
% the function generates a sequence of red (Brownian) noise samples.
% In terms of power at a constant bandwidth, red noise falls off at 6 dB/oct, i.e. 20 dB/dec.

% define the length of the vector and ensure that the M is even.
if rem(N, 2)
    M = N+1;
else
    M = N;
end

% generate white noise
x = randn(1, M);

% FFT
X = fft(x);

% prep a vec with freq indexes
nPts = M/2 + 1;
n = 1:nPts;

% manipulate left half of the spectrum so the PSD is propertional to the
% frequency by a factor of 1/(f^2), or the amplitudes are proportional to 1/f
X = X(1:nPts);
X = X./n;

% prep the right half of the spectrum, a conj. copy of the left
% except the DC component and the Nyquist component, (0 < x < Nq)
X = [X conj(X(end-1:-1:2))];

% IFFT
y = real(ifft(X));

% ensure that the length of y is N.
y = y(1, 1:N);

% ensure unity standard deviation and zero mean value.
y = y - mean(y);
y = y/std(y, 1);

end % rednoise

%-------------------------------------------------------------------------
%                           bluenoise
%-------------------------------------------------------------------------
function y = bluenoise(N)

% function: y = bluenoise(N) 
% N - number of samples to be returned in a row vector
% y - a row vector of blue noise samples

% The function generates a sequence of blue noise samples. 
% In terms of power at a constant bandwidth, blue noise increase in at 3 dB/oct, i.e. 10 dB/dec. 

% difine the length of the vector and
% ensure that the M is even, this will simplify the processing
if rem(N, 2)
    M = N+1;
else
    M = N;
end

% generate white noise 
x = randn(1, M);

% FFT
X = fft(x);

% prepare a vector with frequency indexes 
nPts = M/2 + 1;             % number of the unique fft points
n = 1:nPts;                 % vector with frequency indexes 

% manipulate the left half of the spectrum so the PSD
% is proportional to the frequency by a factor of 1/f, 
% i.e. the amplitudes are proportional to 1/sqrt(f)
X = X(1:nPts);  
X = X.*sqrt(n);

% prepare the right half of the spectrum - a conjugate copy of the left one,
% except the DC component and the Nyquist component - they are unique
% and reconstruct the whole spectrum
X = [X conj(X(end-1:-1:2))];

% IFFT
y = real(ifft(X));

% ensure that the length of y is N
y = y(1, 1:N);

% ensure unity standard deviation and zero mean value
y = y - mean(y);
y = y/std(y, 1);

end % bluenoise

%-----------------------------------------------------
%               violetnoise
%-----------------------------------------------------
function y = violetnoise(N)

% function: y = violetnoise(N) 
% N - number of samples to be returned in a row vector
% y - a row vector of violet noise samples

% The function generates a sequence of violet (purple) noise samples. 
% In terms of power at a constant bandwidth, violet noise increase in at 6 dB/oct, i.e. 20 dB/dec. 

% difine the length of the vector and
% ensure that the M is even, this will simplify the processing
if rem(N, 2)
    M = N+1;
else
    M = N;
end

% generate white noise 
x = randn(1, M);

% FFT
X = fft(x);

% prepare a vector with frequency indexes 
nPts = M/2 + 1;     % number of the unique fft points
n = 1:nPts;         % vector with frequency indexes 

% manipulate the left half of the spectrum so the PSD
% is proportional to the frequency by a factor of f^2, 
% i.e. the amplitudes are proportional to f
X = X(1:nPts);
X = X.*n;

% prepare the right half of the spectrum - a conjugate copy of the left one,
% except the DC component and the Nyquist component - they are unique
% and reconstruct the whole spectrum
X = [X conj(X(end-1:-1:2))];

% IFFT
y = real(ifft(X));

% ensure that the length of y is N
y = y(1, 1:N);

% ensure unity standard deviation and zero mean value
y = y - mean(y);
y = y/std(y, 1);

end % violetnoise
%------------------------------------------------
%               pinknoise
%------------------------------------------------
function y = pinknoise(N)

% function: y = pinknoise(N) 
% N - number of samples to be returned in a row vector
% y - a row vector of pink (flicker) noise samples

% The function generates a sequence of pink (flicker) noise samples. 
% In terms of power at a constant bandwidth, pink noise falls off at 3 dB/oct, i.e. 10 dB/dec. 

% define the length of the vector and
% ensure that the M is even, this will simplify the processing
if rem(N, 2)
    M = N+1;
else
    M = N;
end

% generate white noise
x = randn(1, M);

% FFT
X = fft(x);

% prepare a vector with frequency indexes 
nPts = M/2 + 1;     % number of the unique fft points
n = 1:nPts;         % vector with frequency indexes 

% manipulate the left half of the spectrum so the PSD
% is proportional to the frequency by a factor of 1/f, 
% i.e. the amplitudes are proportional to 1/sqrt(f)
X = X(1:nPts);      
X = X./sqrt(n);

% prepare the right half of the spectrum - a conjugate copy of the left one,
% except the DC component and the Nyquist component - they are unique
% and reconstruct the whole spectrum
X = [X conj(X(end-1:-1:2))];

% IFFT
y = real(ifft(X));

% ensure that the length of y is N
y = y(1, 1:N);

% ensure unity standard deviation and zero mean value
y = y - mean(y);
y = y/std(y, 1);

end % pinknoise
