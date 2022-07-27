function [summarymat, shadingmat, depthrange] = ussummary(depthstart, depthend, nsim, agedepmat, interpinterval, writedir, bootpc, xfactor, depthcombine, savebigmat, proxy, SaveName)

%--- Summarise the data agedepmat data to discrete depth probabilities
depthrange = [depthstart ceil(depthstart):interpinterval:floor(depthend) depthend]';
depthrange = unique(depthrange);
if max(depthrange) < depthend
    depthrange = [depthrange; depthend];
end

% replace depth nans with very negative values (must all be unique or interp will error)
numdeps = length(find(isnan(agedepmat(:,2,:))));
replogical = false(size(agedepmat));
replogical(:,2,:) = isnan(agedepmat(:,2,:));
agedepmat(replogical) = linspace(-9999-numdeps, -9999, numdeps); % always in ascending order
clear replogical

tempage = NaN(length(depthrange),nsim);

% attempt to use faster precompiled binary
try
	checkmex = sum(nakeinterp1([1; 10],[1; 100],(2:2:9)')) == 180;
catch err
end

% Check for presence of precompiled binary
if exist('err','var') == 1
	warning(err.message)
	disp('Compiling nakeinterp1.c will increase speed. Using slower interpolation')
	for i = 1:nsim
		tempage(:,i) = interp1qr(agedepmat(:,2,i),agedepmat(:,1,i),depthrange);
	end

end

% Check that precompiled binary returned correct result before using
if exist('checkmex','var') == 1
	if checkmex ~= 1
		warning('nakeinterp1 binary found but needs to be recompiled (help mex)')
		for i = 1:nsim
			tempage(:,i) = interp1qr(agedepmat(:,2,i),agedepmat(:,1,i),depthrange);
		end
	else
		nakedepthrange = depthrange;
		nakedepthrange(1) = nakedepthrange(1)+(10^-10);
		for i = 1:nsim
			tempage(:,i) = nakeinterp1(agedepmat(:,2,i),agedepmat(:,1,i),nakedepthrange);
		end
	end
end

% create probability density cloud for ages
allprctiles = prctile(tempage,[1:99, 100*(1-erf(2/sqrt(2)))/2, 100*(1-erf(1/sqrt(2)))/2, 100-100*(1-erf(1/sqrt(2)))/2, 100-100*(1-erf(2/sqrt(2)))/2] , 2);

% percent and per gram can't be <0
if contains(proxy,'PER') || contains(proxy,'PGR')
	index = allprctiles < 0;
	allprctiles(index) = 0;
end

% summarize and create matrix from probability density
shadingmat = allprctiles(:,1:99);
summarymat = [allprctiles(:,[50, 100:end]), nanmean(tempage,2)]; % summarymat is: median, 2siglo, 1siglo, 1sighi, 2sighi, mean

% save to disk
if depthcombine == 1
	comtag = 'Yes';
elseif depthcombine == 0
	comtag = 'No'; 
end

fid_output = fopen([SaveName '_stack.txt'],'w');
fprintf(fid_output,'%s',['Unstackable run on ',datestr(now,31),'. nsim=',num2str(nsim),' bootpc=',num2str(bootpc,'%.2g'),' xfactor=',num2str(xfactor,'%.2g'),' combine=',comtag]);
fprintf(fid_output,'\r\n%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s','Depth','Median age','Mean age','95.4% age','68.2% age','68.2% age','95.4% age');
for i = 1:size(depthrange,1)
	fprintf(fid_output,'\r\n%f\t%.0f\t%.0f\t%.0f\t%.0f\t%.0f\t%.0f',depthrange(i),summarymat(i,1),summarymat(i,6),summarymat(i,2),summarymat(i,3),summarymat(i,4),summarymat(i,5));
end
fclose(fid_output);


% Save output (if savemat selected)
if savebigmat == 1
	[~,writename,~] = fileparts(inputfile);
	writename = [writename '_bigmat'];
	save([writedir,writename,'.mat'],'depthrange','tempage')
end

end % end function

