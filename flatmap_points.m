% Map points between native and flat polar coordinates.

clear; close all;
Laplace_radial = niftiread('Laplace_radial.nii.gz');
Laplace_tangential = niftiread('Laplace_tangential.nii.gz');
LBL = niftiread('labelmap-postProc.nii.gz');
hdr = niftiinfo('labelmap-postProc.nii.gz');

i = find(LBL>0);
sz = size(LBL);
[x,y,z] = ind2sub(sz,i);
Laplace_radial = Laplace_radial(i);
Laplace_tangential = Laplace_tangential(i);
LBL = LBL(i);


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
c = [1 0 0;...
    0 1 0;...
    0 0 1;...
    0 1 1;...
    0 0 0];
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
c = [1 0 0;...
    0 1 0;...
    0 0 1;...
    0 1 1;...
    0 0 0];

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
    elseif n==150
      imwrite(imind,cm,filename,'gif', 'DelayTime',1, 'WriteMode','append'); 
    else
      imwrite(imind,cm,filename,'gif', 'DelayTime',1/30, 'WriteMode','append'); 
    end 
end


