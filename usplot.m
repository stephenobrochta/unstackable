udplotoptions % call udplotoptions.m to workspace

% plot dimensions in pixels
figw = 560;
axesl = 50;
axesw = 475;
if plotsar == 1
	figh = 700;
	axesb = [275, 46];
	axesh = [375, 215];
else
	figh = 460;
	axesb = 46;
	axesh = 400;
end

% convert pixel dimensions to relative units so plot can be resized
axesl = axesl / figw;
axesb = axesb ./ figh;
axesw = axesw / figw;
axesh = axesh ./ figh;

% center figure on primary monitor
scrnsze = get(0,'monitorPositions');
if size(scrnsze,1) > 1
	i = find(scrnsze(:,1) == 1);
else
	i = 1;
end
figl = (scrnsze(i,3)/2) - figw / 2;
figb = (scrnsze(i,4)/2) - figh / 2;

% plot age model
figure('position',[figl , figb , figw , figh])
h_age = axes('position',[axesl , axesb(1) , axesw , axesh(1)]);
hold(gca,'on')

			% // ---- paste from here into undatableGUI.m
% Plot density cloud
hcloud = gobjects(49,1);
for i = 1:49
	
	hi1sig=shadingmat(:,99-i);
	lo1sig=shadingmat(:,i);
	
	confx=[
		%right to left at top
		lo1sig(1); hi1sig(1);
		%down to bottom
		hi1sig(2:end);
		%left to right at bottom
		lo1sig(end);
		%up to top
		flipud(lo1sig(1:end-1))];
	
	confy=[
		%right to left at top
		depthrange(1,1); depthrange(1,1);
		%down to bottom
		depthrange(2:end,1);
		%left to right at bottom
		depthrange(end,1);
		%up to top
		flipud(depthrange(1:end-1,1))];
	
	hcloud(i) = patch(confx/1000,confy,[1-(i/49) 1-(i/49) 1-(i/49)],'edgecolor','none');
end
plot(summarymat(:,2)/1000,depthrange,'k--') % 95.4 range
plot(summarymat(:,5)/1000,depthrange,'k--') % 95.4 range
plot(summarymat(:,3)/1000,depthrange,'b--') % 68.2 range
plot(summarymat(:,4)/1000,depthrange,'b--') % 68.2 range

plot(summarymat(:,1)/1000,depthrange,'r')
set(gca,'ydir','reverse','tickdir','out','fontsize',12,'box','on')
ylabel(depthlabel)
if plotsar == 0
	xlabel(agelabel)
end
grid on

% plot the depth error bars
for i = 1:length(depth)
	if depth1(i) <= depth2(i)
		plot( [medians(i)/1000 medians(i)/1000] , [depth1(i) depth2(i)], 'k-' )
	elseif depth1(i) > depth2(i)
		plot( [medians(i)/1000 medians(i)/1000] , [depth1(i)+depth2(i) depth1(i)-depth2(i)], 'k-' )
	end
end

set(gca, 'Layer', 'Top')

% title
if guimode == 0
	[~,NAME,~] = fileparts(inputfile);
	NAME = strrep(NAME,'.txt','');
	NAME = strrep(NAME,'_udinput','');
	title(NAME);
end

% plot all the agedepth runs (debug mode)
if debugme == 1
	for i = 1:size(agedepmat,3)
		plot(agedepmat(:,1,i)/1000,agedepmat(:,2,i),'r.','markersize',2)
		hold on
	end
end

% set paper size (cm)f
set(gcf,'PaperUnits','centimeters')
set(gcf, 'PaperSize',[plotwidth plotheight])
% put figure in top left of paper
set(gcf,'PaperPosition',[0 0 plotwidth plotheight])
% make background white
set(gcf,'InvertHardcopy','on');
set(gcf,'color',[1 1 1]);

% automatic legend (do last before printing so that it appears in the correct place)
usedcolours = unique(usedcolours);
txtxpos = min(xlim) + 0.97 * abs((max(xlim)-min(xlim)));
txtypos = min(ylim) + 0.03 * abs((max(ylim)-min(ylim)));
txtyinc = 0.04 * abs((max(ylim)-min(ylim)));
if length(usedcolours) > 1
	for i = 1:length(usedcolours)
		if i > 1; txtypos = txtypos + txtyinc; end
		h = text(txtxpos, txtypos, strrep(datetypes{usedcolours(i)},'14C','^1^4C'),'horizontalalignment','right','color',colours(1,:,usedcolours(i)));
		set(h,'fontweight','bold')
	end
end

% print the xfactor and bootpc to the bottom left corner
str = ['xfactor = ',num2str(xfactor,'%.2g'),newline,'bootpc = ',num2str(bootpc,'%.2g')];
settingtext = annotation('textbox',get(gca,'position'),'string',str);
set(settingtext,'linestyle','none')
set(settingtext,'horizontalalignment','left')
set(settingtext,'verticalalignment','bottom')

% set all fonts
set(findall(gcf,'-property','FontSize'),'FontSize',textsize)

				% ----/// paste to here into undatableGUI.m

% plot sediment accumulation rate
if plotsar == 1
	set(h_age,'xaxislocation','top');
	xlabel(agelabel)
	h_sar = axes('position',[axesl , axesb(2) , axesw , axesh(2)]);
	hold(gca,'on')
	if ~isempty(sarshadingmat)
		hcloud2 = gobjects(49,1);
		for i = 1:49
	
			hi1sig = sarshadingmat(:,99-i);
			lo1sig = sarshadingmat(:,i);
			
			confy = [
				%right to left at top
				lo1sig(1); hi1sig(1);
				%down to bottom
				hi1sig(2:end);
				%left to right at bottom
				lo1sig(end);
				%up to top
				flipud(lo1sig(1:end-1))];
			
			confx = [
				%right to left at top
				sarsummarymat(1,2)/1000; sarsummarymat(1,2)/1000;
				%down to bottom
				sarsummarymat(2:end,2)/1000;
				%left to right at bottom
				sarsummarymat(end,2)/1000;
				%up to top
				flipud(sarsummarymat(1:end-1,2))/1000];
			
			hcloud2(i) = patch(confx,confy,[1-(i/49) 1-(i/49) 1-(i/49)],'edgecolor','none');
		end
		stairs(sarsummarymat(:,2)/1000,sarsummarymat(:,4),'k--') % 95.4 range
		stairs(sarsummarymat(:,2)/1000,sarsummarymat(:,7),'k--') % 95.4 range
		stairs(sarsummarymat(:,2)/1000,sarsummarymat(:,5),'b--') % 68.2 range
		stairs(sarsummarymat(:,2)/1000,sarsummarymat(:,6),'b--') % 68.2 range
	end
	stairs(sarsummarymat(:,2)/1000,sarsummarymat(:,3),'r-') % modeled SAR
	set(gca,'xlim',get(h_age,'xlim'),'xtick',get(h_age,'xtick'),'xticklabel',get(h_age,'xticklabel'),'tickdir','out','box','on')
	xlabel(agelabel)
	ylabel(sarlabel)
	grid on

end
set(findall(gcf,'-property','FontSize'),'FontSize',textsize)

% print
if printme == 1
	if vcloud == 0 && plotsar == 1
		plot2raster(h_age, hcloud, 'bottom', 300);
		if ~isempty(sarshadingmat)
			plot2raster(h_sar, hcloud2, 'bottom', 300);
		end
	end
	savename = strrep(inputfile,'.txt','_admodel.pdf');
	[~,NAME,EXT] = fileparts(savename);
	savename = [NAME,EXT];
	savename = [writedir,savename];
	print(gcf, '-dpdf', '-painters', savename);
end