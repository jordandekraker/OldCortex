% Map points between native and flat polar coordinates.

clear; close all;
Laplace_radial = niftiread('Laplace_radial.nii');
Laplace_tangential = niftiread('Laplace_tangential.nii');
LBL = niftiread('labelmap-postProc.nii');
hdr = niftiinfo('labelmap-postProc.nii');

i = find(LBL>0);
sz = size(LBL);
[x,y,z] = ind2sub(sz,i);
Laplace_radial = Laplace_radial(i);
Laplace_tangential = Laplace_tangential(i);
LBL = LBL(i);

%%
figure('units','normalized','outerposition',[0 0 1 1])
everyn = 50;
[x,y,z] = ind2sub(sz,i(1:everyn:end));
tl = LBL(1:everyn:end);
tl(tl>4) = 1;
tl(tl==2) = 5;
tl(tl==3) = 2;
tl(tl==5) = 3;
tl(1) = 5;
scatter3(x,y,z,1,tl,'.'); 
axis equal tight off;
colormap('hot');
view(-90,0);

%% rescale and view as polar plot

lt = Laplace_tangential*2*pi - pi;
lt = -lt;
%Laplace_radial = Laplace_radial.^2; % fleshed out extremities
lr = 1-Laplace_radial;

figure;
scatter3(x,y,z,1,lr,'.'); axis equal tight;
view(-90,0);
saveas(gcf,'Laplace_radial-med.png');
view(90,0);
saveas(gcf,'Laplace_radial-lat.png');

figure;
scatter3(x,y,z,1,lt,'.'); axis equal tight;
view(-90,0);
saveas(gcf,'Laplace_tangential-med.png')
view(90,0);
saveas(gcf,'Laplace_tangential-lat.png')

figure;
c = [195 195 195;...
    255 174 200;...
    140 255 251;...
    255 202 24;...
    0 0 0]./255;
l = LBL; l(l>5) = 5;
polarscatter(lt(1:100:end),lr(1:100:end),1,l(1:100:end),'.');
colormap(c);

%% contiguous unfolding gif (linear interpolation)


lt = Laplace_tangential*2*pi - pi;
lt = -lt;
%Laplace_radial = Laplace_radial.^2; % fleshed out extremities
lr = Laplace_radial;

tri = linspace(0,.9999,150);
tri = [tri tri(end:-1:1)];
l = LBL; l(l>5) = 5;
c = [195 195 195;...
    255 174 200;...
    140 255 251;...
    255 202 24;...
    0 0 0]./255;

npts = 50;

zz = zeros(size(LBL));
[xx,yy] = pol2cart(lt+(.5*pi),1-lr);
filename = 'lbl_unfold-linearpts.gif';
x_rs = (x/max(sz)) -.5;
y_rs = (y/max(sz)) -.5;
z_rs = (z/max(sz)) -.5;

figure('units','normalized','outerposition',[0 0 1 1])
for n = 1:length(tri)    
    i = x_rs*(1-tri(n)) + zz*(tri(n));
    j = y_rs*(1-tri(n)) + xx*(tri(n));
    k = z_rs*(1-tri(n)) + yy*(tri(n));
    scatter3(i(1:npts:end),j(1:npts:end),k(1:npts:end),1,l(1:npts:end),'.'); 
    axis equal tight;
    colormap(c);
    view(-90,0);
    drawnow
    
    [imind,cm] = rgb2ind(frame2im(getframe(gcf)),256);
    % Write to the GIF File 
    if n == 1 
      imwrite(imind,cm,filename,'gif', 'DelayTime',1, 'Loopcount',inf); 
      imwrite(imind,cm,'initialfold','png'); 
    elseif n==150
      imwrite(imind,cm,filename,'gif', 'DelayTime',1, 'WriteMode','append'); 
      imwrite(imind, cm, 'finalfold', 'png');
    else
      imwrite(imind,cm,filename,'gif', 'DelayTime',1/30, 'WriteMode','append'); 
    end 
end


