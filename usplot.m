usplotoptions % call udplotoptions.m to workspace

figure('position',[figl , figb , figw , figh])
h_age = axes('position',[axesl , axesb(1) , axesw , axesh]);
hold(h_age,'on')

hcloud = gobjects(49,1);
for i = 1:49
	
	hi1sig=shadingmat(:,99-i);
	lo1sig=shadingmat(:,i);
	
	confy=[
		%right to left at top
		lo1sig(1); hi1sig(1);
		%down to bottom
		hi1sig(2:end);
		%left to right at bottom
		lo1sig(end);
		%up to top
		flipud(lo1sig(1:end-1))];
	
	confx=[
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
% plot(depthrange,summarymat(:,2)/1000,'k--') % 95.4 range
% plot(depthrange,summarymat(:,5)/1000,'k--') % 95.4 range
% plot(depthrange,summarymat(:,3)/1000,'b--') % 68.2 range
% plot(depthrange,summarymat(:,4)/1000,'b--') % 68.2 range

plot(depthrange/1000,summarymat(:,1),'r')

set(h_age,'ydir','normal','tickdir','out','box','on')
% reverse Y axis for NPS and d18O
if contains(proxy,'NPS') || contains(proxy,'OX')
	set(h_age,'ydir','reverse')
end
ylabel(proxy_str)
xlabel(agelabel)
grid on

% plot the depth error bars
% for i = 1:length(depth)
% 	if depth1(i) <= depth2(i)
% 		plot( [medians(i)/1000 medians(i)/1000] , [depth1(i) depth2(i)], 'k-' )
% 	elseif depth1(i) > depth2(i)
% 		plot( [medians(i)/1000 medians(i)/1000] , [depth1(i)+depth2(i) depth1(i)-depth2(i)], 'k-' )
% 	end
% end

% title
title(strrep(Title,'_','\_'));

% plot all the agedepth runs (debug mode)
if debugme == 1
	for i = 1:size(agedepmat,3)
		plot(agedepmat(:,1,i)/1000,agedepmat(:,2,i),'r.','markersize',2)
		hold on
	end
end

% set paper size (cm)f
set(gcf,'PaperUnits','centimeters','PaperSize',[plotwidth plotheight],'PaperPosition',[0.25 0 plotwidth plotheight] ,'InvertHardcopy','on', 'color',[1 1 1]);

% print the xfactor and bootpc to the top rightclose corner
str = ['xfactor = ',num2str(xfactor,'%.2g'),newline,'bootpc = ',num2str(bootpc,'%.2g')];
settingtext = annotation('textbox',get(h_age,'position'),'string',str);
set(settingtext,'linestyle','none','horizontalalignment','right','verticalalignment','top')

% set all fonts
set(findall(gcf,'-property','FontSize'),'FontSize',textsize)

% print
if printme == 1
	if vcloud == 0
		plot2raster(h_age, hcloud, 'bottom', 300);
	end

	savename = strrep(SaveName,'.txt','_admodel.pdf');
	[~,NAME,EXT] = fileparts(savename);
	savename = [NAME,EXT];
	savename = [writedir,savename];
	print(gcf, '-dpdf', '-painters', savename);
end