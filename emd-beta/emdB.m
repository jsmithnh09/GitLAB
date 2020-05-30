function Y = emdB(IMF)
	% EMD_BETA, utilizes the global convergence method and the variance
	% stabilization transform Confidence Interval to optimize the null
	% hypothesis filtering of IMFs [1].
	%
	% See Also: gcm_search, emdH.
	%
  % [1] Smith, Jordan R., Mahdi H. Al-Badrawi, and Nicholas J. Kirsch. 
  %   "An Optimized De-Noising Scheme Based on the Null Hypothesis of Intrinsic Mode Functions." 
  %   IEEE Signal Processing Letters 26.8 (2019): 1232-1236.

	[r, c] = size(IMF);
	if(r > c)
		error('EMD-Beta::enforce IMF row-dominance.');
	end

	% number of time-domain samples.
	N = length(IMF(1,:));

	for i = 2:r
		R = IMF(i,:);	% storing mode as (R)andom variable.
		I = 4;			% initial estimate.

    % Newton-Raphson GCM Search for estimate.
		[P, ~] = gcm_search(R,I,10);

		% Confidence Interval.
		Z = 2.576;
		Lower = (coth(acoth(sqrt(P + 1)) + ((1/(sqrt(2*N)))*Z))^2) - 1;
        Upper = (coth(acoth(sqrt(P + 1)) - ((1/(sqrt(2*N)))*Z))^2) - 1;

		% Scenario Check.
		if(Lower < 1) && (Upper <= 1)	% 0 < p < 1.
			H(i) = 1;

		elseif(Lower >= 1) && ( Upper <= 3) % EMD-H region.
			V = R;
			alpha = 0.01;   % significance level.
			tail = 0;       % two-tail test.

			% Shapiro-Wilk/Francia Test (AS R94)
			[G, pValue, W] = swtest(V, alpha, tail);

			% normalize the sample.
			V = V - mean(V);
			V = V / std(V);

			% search axis for GGD-null sweep.
			dB = 0.01;
			Beta = Lower;
			while(G == 1) && (Beta < Upper)
				rho = sqrt( gamma(1/Beta)/gamma(3/Beta) );
				CDF = 0.5 + sign(V).*gammainc( (abs(V) / rho).^Beta, (1/Beta) );
				Beta = Beta + dB;
				[G, pValue, W] = swtest( erfinv(2*CDF - 1), alpha, tail);
			end
			if(G == 1)
				H(i) = 1;
			else
				H(i) = 0;
			end

		elseif(Lower < 3) && (Upper >= 3)
			V = R;
			alpha = 0.01;
			tail = 0;

			% original Shapiro-Wilk/Francia Test
			[G, pValue, W] = swtest(V, alpha, tail);

			% normalize the sample.
			V = V - mean(V);
			V = V / std(V);

			% search axis for GGD-null sweep.
			dB = 0.01;
			Beta = Lower;
			while(G == 1) && (Beta < Upper)
				rho = sqrt( gamma(1/Beta)/gamma(3/Beta) );
				CDF = 0.5 + sign(V).*gammainc( (abs(V) / rho).^Beta, (1/Beta) );
				Beta = Beta + dB;
				[G, pValue, W] = swtest( erfinv(2*CDF - 1), alpha, tail);
			end
			if(G == 1)
				H(i) = 1;
			else
				H(i) = 0;
			end

		elseif(Lower >= 3) && (Upper > 3)	% subgaussian shape.
			H(i) = 1;

		else
			H(i) = 1;
		end 	% endif
	end 	% endfor

	% Reference Selection.
	for d = 2:r
		if H(d) == 1
			m = d;
			break;
        else
            % default in case of no reference selection.
			m = 2;
		end
	end
	
	rec = 0;

	% Partial Reconstruction.
	for j = m:r
		rec = rec + IMF(j,:);
	end
	Y = rec;

end % EOF
